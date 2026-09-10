import '../../domain/entities/agenda_item.dart';
import '../../domain/entities/announcement.dart';
import 'pdf_text.dart';

class AnnouncementParser {
  const AnnouncementParser();

  static final _introStart = RegExp(
    r'^Am\s+\w+,\s*dem\s+\d{1,2}\.\d{1,2}\.\d{4}',
  );
  static final _issuedOn = RegExp(r'^Langenzenn,\s*(.+)$');
  static final _agendaHeading = RegExp(r'^Tagesordnung$');
  static final _introTail = RegExp(
    r'\s(?:die|der|das|eine|einen|ein)(?:\s+öffentliche\w*)?$',
  );

  Announcement parse(String rawText) {
    final lines = withoutPageFurniture(toLines(rawText));

    final headingIndex = _findHeadingIndex(lines);
    final heading = headingIndex < 0 ? '' : _readHeading(lines, headingIndex);
    final intro = _readIntro(lines, headingIndex);
    final agenda = _readAgenda(lines);

    return Announcement(
      heading: heading,
      sessionNumber: parseSessionNumber(heading),
      date: intro == null ? null : parseGermanDate(intro.text),
      startTime: intro == null ? null : parseTime(intro.text),
      location: intro?.location,
      agenda: agenda.items,
      notes: agenda.notes,
      closingNote: _readClosingNote(lines),
      issuedOn: _readIssuedOn(lines),
      signedBy: _readSignature(lines),
    );
  }

  /// The heading sits directly above `Tagesordnung`, separated only by the
  /// `mit folgender ...` line. Anchoring there is stable, while the sentence
  /// before it ends on `die` in some announcements and on `eine öffentliche`
  /// in others.
  int _findHeadingIndex(List<TextLine> lines) {
    final agenda = lines.indexWhere(
      (line) => _agendaHeading.hasMatch(line.text),
    );
    if (agenda < 0) return -1;
    for (var index = agenda - 1; index >= 0; index--) {
      final text = lines[index].text;
      if (text.isEmpty || text.startsWith('mit folgender')) continue;
      return index;
    }
    return -1;
  }

  /// A heading may wrap, as in `1. Gemeinsame Sitzung des Werkausschusses` /
  /// `und des Hauptausschusses`. Collecting upwards stops at the sentence that
  /// announces the session, which ends on its article.
  String _readHeading(List<TextLine> lines, int headingIndex) {
    final collected = <String>[lines[headingIndex].text];
    for (var index = headingIndex - 1; index >= 0; index--) {
      final text = lines[index].text;
      if (text.isEmpty || _isIntroText(text)) break;
      collected.insert(0, text);
    }
    return normalizeSpaces(collected.join(' '));
  }

  bool _isIntroText(String text) =>
      _introStart.hasMatch(text) ||
      text.contains(' findet ') ||
      _introTail.hasMatch(text);

  _Intro? _readIntro(List<TextLine> lines, int headingIndex) {
    final start = lines.indexWhere((line) => _introStart.hasMatch(line.text));
    if (start < 0) return null;

    final end = headingIndex > start
        ? headingIndex
        : (start + 6).clamp(0, lines.length);
    final collected = [
      for (var index = start; index < end; index++)
        if (lines[index].text.isNotEmpty) lines[index].text,
    ];

    final joined = normalizeSpaces(collected.join(' '));
    return _Intro(text: joined, location: _extractLocation(joined));
  }

  String? _extractLocation(String intro) {
    final match = RegExp(r'findet\s+(.*)$').firstMatch(intro);
    if (match == null) return null;
    final location = normalizeSpaces(match.group(1)!)
        .replaceFirst(_introTail, '')
        .replaceFirst(RegExp(r'^(?:im|in der|in|am|auf dem)\s+'), '');
    return location.isEmpty ? null : location;
  }

  _Agenda _readAgenda(List<TextLine> lines) {
    final start = lines.indexWhere(
      (line) => _agendaHeading.hasMatch(line.text),
    );
    if (start < 0) return const _Agenda([], []);

    final items = <AgendaItem>[];
    final notes = <String>[];
    var pending = <String>[];
    String? pendingNumber;

    void flush() {
      final number = pendingNumber;
      if (number == null) return;
      items.add(AgendaItem(number: number, title: joinWrapped(pending)));
      pendingNumber = null;
      pending = <String>[];
    }

    for (var index = start + 1; index < lines.length; index++) {
      final line = lines[index];
      final text = line.text;
      if (text.isEmpty) continue;
      if (text == 'statt:') continue;
      if (_isClosingNote(text) || _issuedOn.hasMatch(text)) break;

      final numbered = matchNumberedItem(text);
      if (numbered != null) {
        flush();
        pendingNumber = numbered.number;
        pending = [numbered.rest];
        continue;
      }
      if (pendingNumber != null) {
        pending.add(text);
      } else {
        notes.add(normalizeSpaces(text));
      }
    }
    flush();
    return _Agenda(items, notes);
  }

  bool _isClosingNote(String text) =>
      text.startsWith('Die hier fehlenden Tagesordnungspunkte');

  String? _readClosingNote(List<TextLine> lines) {
    final index = lines.indexWhere((line) => _isClosingNote(line.text));
    if (index < 0) return null;
    final collected = <String>[];
    for (var i = index; i < lines.length; i++) {
      if (lines[i].text.isEmpty) break;
      collected.add(lines[i].text);
    }
    return joinWrapped(collected);
  }

  String? _readIssuedOn(List<TextLine> lines) {
    for (final line in lines) {
      final match = _issuedOn.firstMatch(line.text);
      if (match != null) return normalizeSpaces(match.group(1)!);
    }
    return null;
  }

  String? _readSignature(List<TextLine> lines) {
    final issuedIndex = lines.indexWhere(
      (line) => _issuedOn.hasMatch(line.text),
    );
    if (issuedIndex < 0) return null;
    final collected = <String>[];
    for (var index = issuedIndex + 1; index < lines.length; index++) {
      final text = lines[index].text;
      if (text.isEmpty) continue;
      if (text.toUpperCase() == text && text.contains('LANGENZENN')) continue;
      collected.add(text);
    }
    if (collected.isEmpty) return null;
    return collected.join(', ');
  }
}

class _Intro {
  const _Intro({required this.text, required this.location});

  final String text;
  final String? location;
}

class _Agenda {
  const _Agenda(this.items, this.notes);

  final List<AgendaItem> items;
  final List<String> notes;
}
