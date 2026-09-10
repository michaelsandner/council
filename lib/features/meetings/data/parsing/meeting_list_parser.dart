import 'package:html/dom.dart';
import 'package:html/parser.dart' as html;

import '../../domain/entities/meeting.dart';
import '../../domain/entities/meeting_document.dart';
import 'pdf_text.dart';

/// Reads the session table of a SessionNet `si0046.php` page.
class MeetingListParser {
  const MeetingListParser({required this.baseUrl});

  final String baseUrl;

  static final _timeRange = RegExp(r'(\d{1,2}:\d{2})(?:\s*-\s*(\d{1,2}:\d{2}))?');
  static final _sessionId = RegExp(r'__ksinr=(\d+)');
  static final _calendarKey = RegExp(r'[?&]key=(\d+)');
  static final _documentId = RegExp(r'[?&]id=(\d+)');

  List<Meeting> parse(String rawHtml) {
    final document = html.parse(rawHtml);
    final table = document.querySelector('table.smctablesitzungen');
    if (table == null) return const [];

    final meetings = <Meeting>[];
    DateTime? lastDate;

    for (final row in table.querySelectorAll('tr')) {
      if (row.querySelector('th') != null) continue;

      final date = _readDate(row) ?? lastDate;
      if (date == null) continue;
      lastDate = date;

      final title = _readTitle(row);
      if (title == null || title.isEmpty) continue;

      final documents = _readDocuments(row);
      final times = _readTimes(row);

      meetings.add(
        Meeting(
          id: _readId(row, date, title),
          title: title,
          date: date,
          startTime: times.$1,
          endTime: times.$2,
          location: _readLocation(row),
          announcement: documents[MeetingDocumentKind.announcement],
          minutes: documents[MeetingDocumentKind.minutes],
        ),
      );
    }
    return meetings;
  }

  DateTime? _readDate(Element row) {
    final cell = row.querySelector('td.sidat_tag');
    if (cell == null) return null;
    return parseGermanDate(_text(cell));
  }

  String? _readTitle(Element row) {
    final cell = row.querySelector('td.silink');
    if (cell == null) return null;
    final holder = cell.querySelector('div.smc-el-h');
    if (holder == null) return null;
    final link = holder.querySelector('a');
    return normalizeSpaces(_text(link ?? holder));
  }

  (String?, String?) _readTimes(Element row) {
    final entries = row.querySelectorAll('td.silink ul.smc-detail-list li');
    for (final entry in entries) {
      final text = _text(entry);
      if (!text.contains('Uhr')) continue;
      final match = _timeRange.firstMatch(text);
      if (match != null) return (match.group(1), match.group(2));
    }
    return (null, null);
  }

  String? _readLocation(Element row) {
    final entries = row.querySelectorAll('td.silink ul.smc-detail-list li');
    for (final entry in entries) {
      final text = normalizeSpaces(_text(entry));
      if (text.isEmpty || text.contains('Uhr')) continue;
      return text;
    }
    return null;
  }

  String _readId(Element row, DateTime date, String title) {
    for (final link in row.querySelectorAll('a')) {
      final href = link.attributes['href'] ?? '';
      final session = _sessionId.firstMatch(href) ?? _calendarKey.firstMatch(href);
      if (session != null) return session.group(1)!;
    }
    final day = date.toIso8601String().substring(0, 10);
    final slug = title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    return '$day-$slug';
  }

  Map<MeetingDocumentKind, MeetingDocument> _readDocuments(Element row) {
    final documents = <MeetingDocumentKind, MeetingDocument>{};

    for (final box in row.querySelectorAll('td.sidocs div.smc-d-el')) {
      final href = box
          .querySelectorAll('a')
          .map((candidate) => candidate.attributes['href'])
          .firstWhere(
            (candidate) => candidate != null && candidate.contains('getfile.php'),
            orElse: () => null,
          );
      if (href == null) continue;

      final id = _documentId.firstMatch(href)?.group(1);
      if (id == null) continue;

      final label = normalizeSpaces(_text(box));
      final kind = _kindOf(_text(box.querySelector('i.smc-doc-dakurz')), label);
      if (kind == null || documents.containsKey(kind)) continue;

      documents[kind] = MeetingDocument(
        id: id,
        kind: kind,
        label: label.isEmpty ? _defaultLabel(kind) : label,
        sourceUrl: _absolute(href),
      );
    }
    return documents;
  }

  MeetingDocumentKind? _kindOf(String code, String label) {
    final marker = code.toUpperCase();
    if (marker.startsWith('BM')) return MeetingDocumentKind.announcement;
    if (marker.startsWith('N')) return MeetingDocumentKind.minutes;
    if (label.contains('Bekanntmachung')) return MeetingDocumentKind.announcement;
    if (label.contains('Niederschrift')) return MeetingDocumentKind.minutes;
    return null;
  }

  String _defaultLabel(MeetingDocumentKind kind) =>
      kind == MeetingDocumentKind.announcement
      ? 'Öffentliche Bekanntmachung'
      : 'Niederschrift';

  String _absolute(String href) {
    if (href.startsWith('http')) return href;
    final base = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    return '$base${href.startsWith('/') ? href.substring(1) : href}';
  }

  String _text(Element? element) =>
      (element?.text ?? '').replaceAll(' ', ' ').trim();
}
