import '../../domain/entities/attendance.dart';
import '../../domain/entities/minutes.dart';
import '../../domain/entities/vote_result.dart';
import 'pdf_text.dart';

class MinutesParser {
  const MinutesParser();

  /// Page breaks can shift an item number a column to the right.
  static const _itemIndentTolerance = 2;

  static final _headingMarker = RegExp(r'Auszug aus der Niederschrift');
  static final _publicPart = RegExp(r'^Öffentlicher Teil$');
  static final _presentMarker = RegExp(r'^Zur Sitzung anwesend:');
  static final _absentMarker = RegExp(r'^(Abwesend|Entschuldigt)');
  static final _member = RegExp(r'^[^,]+,\s*\S');
  static final _vote = RegExp(
    r'Daf[üu]r:\s*(\d+)?\s*(?:Dagegen:\s*(\d+)?)?\s*(?:Anwesend:\s*(\d+)?)?',
  );

  Minutes parse(String rawText) {
    final lines = withoutPageFurniture(toLines(rawText));

    final heading = _readHeading(lines);
    final fields = _readFields(lines);
    final bodyStart = lines.indexWhere(
      (line) => _publicPart.hasMatch(line.text),
    );

    return Minutes(
      heading: heading,
      sessionNumber: parseSessionNumber(heading),
      date: fields['Sitzungsdatum'] == null
          ? null
          : parseGermanDate(fields['Sitzungsdatum']!),
      startTime: fields['Beginn'] == null ? null : parseTime(fields['Beginn']!),
      endTime: fields['Ende'] == null ? null : parseTime(fields['Ende']!),
      location: fields['Ort, Raum'],
      present: _readAttendance(lines, _presentMarker, bodyStart),
      absent: _readAttendance(lines, _absentMarker, bodyStart),
      items: bodyStart < 0
          ? const []
          : _readItems(lines.sublist(bodyStart + 1)),
    );
  }

  String _readHeading(List<TextLine> lines) {
    final marker = lines.indexWhere(
      (line) => _headingMarker.hasMatch(line.text),
    );
    if (marker < 0) return '';
    for (var index = marker + 1; index < lines.length; index++) {
      final text = lines[index].text;
      if (text.isNotEmpty) return normalizeSpaces(text);
    }
    return '';
  }

  Map<String, String> _readFields(List<TextLine> lines) {
    const labels = ['Sitzungsdatum', 'Beginn', 'Ende', 'Ort, Raum'];
    final fields = <String, String>{};
    final headerEnd = _headerEnd(lines);

    for (var index = 0; index < headerEnd; index++) {
      final text = lines[index].text;
      final label = labels.firstWhere(
        (candidate) =>
            text.startsWith('$candidate:') || text.startsWith('$candidate '),
        orElse: () => '',
      );
      if (label.isEmpty || fields.containsKey(label)) continue;

      final value = text
          .substring(label.length)
          .replaceFirst(RegExp(r'^\s*:'), '')
          .trim();
      final collected = <String>[if (value.isNotEmpty) value];

      for (var next = index + 1; next < lines.length; next++) {
        final continuation = lines[next];
        if (continuation.isBlank) break;
        if (_startsNewField(continuation.text, labels)) break;
        if (continuation.indent < lines[index].indent) break;
        collected.add(continuation.text);
      }
      fields[label] = joinWrapped(collected);
    }
    return fields;
  }

  int _headerEnd(List<TextLine> lines) {
    final end = lines.indexWhere(
      (line) =>
          _publicPart.hasMatch(line.text) ||
          _presentMarker.hasMatch(line.text) ||
          _absentMarker.hasMatch(line.text),
    );
    return end < 0 ? lines.length : end;
  }

  bool _startsNewField(String text, List<String> labels) =>
      labels.any((label) => text.startsWith(label)) ||
      _presentMarker.hasMatch(text) ||
      _absentMarker.hasMatch(text) ||
      _publicPart.hasMatch(text);

  List<AttendanceGroup> _readAttendance(
    List<TextLine> lines,
    RegExp marker,
    int bodyStart,
  ) {
    final start = lines.indexWhere((line) => marker.hasMatch(line.text));
    if (start < 0) return const [];
    final limit = bodyStart < 0 ? lines.length : bodyStart;
    if (start >= limit) return const [];

    final groups = <AttendanceGroup>[];
    var role = '';
    var members = <Attendee>[];

    void flush() {
      if (members.isEmpty) return;
      groups.add(AttendanceGroup(role: role, members: members));
      members = <Attendee>[];
    }

    for (var index = start + 1; index < limit; index++) {
      final text = lines[index].text;
      if (text.isEmpty) continue;
      if (_presentMarker.hasMatch(text) || _absentMarker.hasMatch(text)) break;

      if (_member.hasMatch(text)) {
        members.add(_readAttendee(text));
      } else {
        flush();
        role = normalizeSpaces(text);
      }
    }
    flush();
    return groups;
  }

  Attendee _readAttendee(String text) {
    final parts = text.split(RegExp(r'\s{2,}'));
    final name = normalizeSpaces(parts.first);
    final note = parts.length > 1
        ? normalizeSpaces(parts.sublist(1).join(' '))
        : null;
    return Attendee(
      name: name,
      note: note == null || note.isEmpty ? null : note,
    );
  }

  List<MinutesItem> _readItems(List<TextLine> lines) {
    final items = <MinutesItem>[];
    var block = <TextLine>[];
    String? number;
    var titleLines = <String>[];

    void flush() {
      final current = number;
      if (current == null) return;
      items.add(_buildItem(current, titleLines, block));
      number = null;
      titleLines = <String>[];
      block = <TextLine>[];
    }

    for (final line in lines) {
      final numbered = line.indent <= _itemIndentTolerance
          ? matchNumberedItem(line.text)
          : null;
      if (numbered != null && !_isSessionReference(numbered.rest)) {
        flush();
        number = numbered.number;
        titleLines = [numbered.rest];
        continue;
      }
      if (number == null) continue;
      block.add(line);
    }
    flush();
    return items;
  }

  /// Minutes quote other sessions as `64. Sitzung des ... vom 24.06.2026`,
  /// which is shaped exactly like an agenda item but belongs to the body text.
  bool _isSessionReference(String rest) => rest.startsWith('Sitzung ');

  MinutesItem _buildItem(
    String number,
    List<String> titleLines,
    List<TextLine> block,
  ) {
    final title = <String>[...titleLines];
    final sections = <String, List<String>>{};
    String? section;

    for (final line in block) {
      final text = line.text;
      if (text == 'Sachverhalt:') {
        section = 'facts';
        sections[section] = <String>[];
        continue;
      }
      if (text == 'Beschluss:' || text == 'Beschluss') {
        section = 'decision';
        sections[section] = <String>[];
        continue;
      }
      if (section == null) {
        if (text.isNotEmpty) title.add(text);
        continue;
      }
      sections[section]!.add(text);
    }

    final decisionLines = sections['decision'] ?? const <String>[];
    final vote = _readVote(decisionLines);

    return MinutesItem(
      number: number,
      title: joinWrapped(title),
      facts: _asBlock(sections['facts']),
      decision: _asBlock(
        vote == null
            ? decisionLines
            : decisionLines.where((line) => !_vote.hasMatch(line)).toList(),
      ),
      vote: vote,
    );
  }

  String? _asBlock(List<String>? lines) {
    if (lines == null) return null;
    final text = joinWrapped(lines);
    return text.isEmpty ? null : text;
  }

  VoteResult? _readVote(List<String> lines) {
    for (final line in lines) {
      final match = _vote.firstMatch(line);
      if (match == null) continue;
      final summary = normalizeSpaces(line.substring(0, match.start));
      return VoteResult(
        summary: summary.replaceFirst(RegExp(r':$'), ''),
        inFavour: _toInt(match.group(1)),
        against: _toInt(match.group(2)),
        present: _toInt(match.group(3)),
      );
    }
    return null;
  }

  int? _toInt(String? value) => value == null ? null : int.tryParse(value);
}
