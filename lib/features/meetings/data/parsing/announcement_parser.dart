import '../../domain/entities/agenda_item.dart';
import '../../domain/entities/announcement.dart';
import 'pdf_text.dart';

class AnnouncementParser {
  const AnnouncementParser();

  static final _introStart = RegExp(r'^Am\s+\w+,\s*dem\s+\d{1,2}\.\d{1,2}\.\d{4}');
  static final _issuedOn = RegExp(r'^Langenzenn,\s*(.+)$');
  static final _agendaHeading = RegExp(r'^Tagesordnung$');

  Announcement parse(String rawText) {
    final lines = withoutPageFurniture(toLines(rawText));

    final intro = _readIntro(lines);
    final heading = intro == null
        ? const _Heading('')
        : _readHeading(lines, intro.endIndex);
    final agenda = _readAgenda(lines);

    return Announcement(
      heading: heading.text,
      sessionNumber: parseSessionNumber(heading.text),
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

  _Intro? _readIntro(List<TextLine> lines) {
    final start = lines.indexWhere((line) => _introStart.hasMatch(line.text));
    if (start < 0) return null;

    final collected = <String>[];
    var index = start;
    while (index < lines.length) {
      final text = lines[index].text;
      if (text.isNotEmpty) collected.add(text);
      if (text.endsWith(' die') || text == 'die') break;
      if (collected.length > 6) break;
      index++;
    }

    final joined = normalizeSpaces(collected.join(' '));
    return _Intro(
      text: joined,
      location: _extractLocation(joined),
      endIndex: index + 1,
    );
  }

  String? _extractLocation(String intro) {
    final match = RegExp(r'findet\s+(.*?)\s+die$').firstMatch(intro);
    if (match == null) return null;
    final location = normalizeSpaces(match.group(1)!)
        .replaceFirst(RegExp(r'^(im|in der|in|am|auf dem)\s+'), '');
    return location.isEmpty ? null : location;
  }

  _Heading _readHeading(List<TextLine> lines, int from) {
    final collected = <String>[];
    for (var index = from; index < lines.length; index++) {
      final text = lines[index].text;
      if (text.isEmpty) {
        if (collected.isNotEmpty) break;
        continue;
      }
      if (text.startsWith('mit folgender') || _agendaHeading.hasMatch(text)) {
        break;
      }
      collected.add(text);
      if (collected.length > 3) break;
    }
    return _Heading(normalizeSpaces(collected.join(' ')));
  }

  _Agenda _readAgenda(List<TextLine> lines) {
    final start = lines.indexWhere((line) => _agendaHeading.hasMatch(line.text));
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
    final issuedIndex = lines.indexWhere((line) => _issuedOn.hasMatch(line.text));
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
  const _Intro({required this.text, required this.location, required this.endIndex});

  final String text;
  final String? location;
  final int endIndex;
}

class _Heading {
  const _Heading(this.text);

  final String text;
}

class _Agenda {
  const _Agenda(this.items, this.notes);

  final List<AgendaItem> items;
  final List<String> notes;
}
