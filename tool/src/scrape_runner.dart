import 'package:council/features/meetings/data/parsing/announcement_parser.dart';
import 'package:council/features/meetings/data/parsing/meeting_list_parser.dart';
import 'package:council/features/meetings/data/parsing/minutes_parser.dart';
import 'package:council/features/meetings/domain/entities/meeting.dart';
import 'package:council/features/meetings/domain/entities/meeting_document.dart';

import 'council_archive.dart';
import 'pdf_text_extractor.dart';
import 'session_net_client.dart';

typedef ProgressLog = void Function(String message);

class ScrapeRunner {
  ScrapeRunner({
    required this.client,
    required this.archive,
    required this.extractor,
    required this.log,
    this.announcementParser = const AnnouncementParser(),
    this.minutesParser = const MinutesParser(),
  });

  final SessionNetClient client;
  final CouncilArchive archive;
  final PdfTextExtractor extractor;
  final ProgressLog log;
  final AnnouncementParser announcementParser;
  final MinutesParser minutesParser;

  Future<ScrapeReport> run({
    required int fromYear,
    required int toYear,
    bool force = false,
  }) async {
    final listParser = MeetingListParser(baseUrl: client.baseUrl);
    final previous = {
      for (final meeting in archive.readMeetings()) meeting.id: meeting,
    };
    final reparseAll = force || archive.isStale;
    if (reparseAll) {
      log('Parser-Version geändert: alle Dokumente werden neu gelesen');
    }

    final meetings = <String, Meeting>{};
    for (var year = fromYear; year <= toYear; year++) {
      final pages = [
        await client.fetchAppointments(year),
        await client.fetchMinutesIndex(year),
      ];
      for (final page in pages) {
        for (final meeting in listParser.parse(page)) {
          meetings[meeting.id] = _merge(meetings[meeting.id], meeting);
        }
      }
      log('$year: ${meetings.length} Sitzungen bekannt');
    }

    final ordered = meetings.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final report = ScrapeReport();
    for (final meeting in ordered) {
      await _syncDetail(meeting, previous[meeting.id], report, reparseAll);
    }

    archive.writeIndex(ordered, source: client.baseUrl);
    archive.removeDetailsExcept(ordered.map((meeting) => meeting.id).toSet());
    report.totalMeetings = ordered.length;
    return report;
  }

  Meeting _merge(Meeting? existing, Meeting incoming) {
    if (existing == null) return incoming;
    return Meeting(
      id: incoming.id,
      title: incoming.title,
      date: incoming.date,
      startTime: incoming.startTime ?? existing.startTime,
      endTime: incoming.endTime ?? existing.endTime,
      location: incoming.location ?? existing.location,
      announcement: incoming.announcement ?? existing.announcement,
      minutes: incoming.minutes ?? existing.minutes,
    );
  }

  Future<void> _syncDetail(
    Meeting meeting,
    Meeting? previous,
    ScrapeReport report,
    bool reparseAll,
  ) async {
    if (!meeting.hasDetails) return;

    final stored = archive.readDetail(meeting.id);
    final refetch =
        reparseAll || (previous != null && _scheduleChanged(previous, meeting));

    final needsAnnouncement = _needsDownload(
      meeting.announcement,
      stored?.announcementDocumentId,
      refetch,
    );
    final needsMinutes = _needsDownload(
      meeting.minutes,
      stored?.minutesDocumentId,
      refetch,
    );

    if (!needsAnnouncement && !needsMinutes) return;

    var announcement = stored?.announcement;
    var minutes = stored?.minutes;

    if (needsAnnouncement) {
      final document = meeting.announcement!;
      log(
        '  ↓ Bekanntmachung ${document.id} (${meeting.title}, '
        '${_day(meeting.date)})',
      );
      final text = await _textOf(document);
      announcement = announcementParser.parse(text);
      report.downloadedAnnouncements++;
    }
    if (needsMinutes) {
      final document = meeting.minutes!;
      log(
        '  ↓ Niederschrift ${document.id} (${meeting.title}, '
        '${_day(meeting.date)})',
      );
      final text = await _textOf(document);
      minutes = minutesParser.parse(text);
      report.downloadedMinutes++;
    }

    archive.writeDetail(
      meeting.id,
      StoredDetail(
        announcement: announcement,
        minutes: minutes,
        announcementDocumentId: meeting.announcement?.id,
        minutesDocumentId: meeting.minutes?.id,
      ),
    );
  }

  bool _needsDownload(
    MeetingDocument? document,
    String? storedDocumentId,
    bool refetch,
  ) {
    if (document == null) return false;
    return refetch || storedDocumentId != document.id;
  }

  bool _scheduleChanged(Meeting previous, Meeting current) =>
      previous.date != current.date ||
      previous.startTime != current.startTime ||
      previous.endTime != current.endTime;

  Future<String> _textOf(MeetingDocument document) async {
    final bytes = await client.downloadDocument(document.id);
    return extractor.extract(bytes);
  }

  String _day(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.'
      '${date.month.toString().padLeft(2, '0')}.${date.year}';
}

class ScrapeReport {
  int totalMeetings = 0;
  int downloadedAnnouncements = 0;
  int downloadedMinutes = 0;

  bool get changed => downloadedAnnouncements > 0 || downloadedMinutes > 0;

  @override
  String toString() =>
      '$totalMeetings Sitzungen, $downloadedAnnouncements neue Bekanntmachungen, '
      '$downloadedMinutes neue Niederschriften';
}
