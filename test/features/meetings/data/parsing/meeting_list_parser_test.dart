import 'package:council/features/meetings/data/parsing/meeting_list_parser.dart';
import 'package:council/features/meetings/domain/entities/meeting_document.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/fixtures.dart';

void main() {
  const parser = MeetingListParser(
    baseUrl: 'https://www.buergerinfo-langenzenn.de',
  );

  group('given the appointments tab', () {
    final meetings = parser.parse(fixture('appointments_list.html'));

    test('then every session row becomes a meeting', () {
      expect(meetings, hasLength(5));
    });

    test('then it reads title, date, time and location', () {
      final first = meetings.first;
      expect(first.title, 'Ferienausschuss');
      expect(first.date, DateTime(2026, 9, 1));
      expect(first.startTime, '17:00');
      expect(
        first.location,
        'Sitzungssaal des Alten Rathauses in Langenzenn, Prinzregentenplatz 1',
      );
    });

    test('then it uses the session id of the source system', () {
      expect(meetings.first.id, '3442');
      expect(meetings.map((meeting) => meeting.id), contains('3443'));
    });

    test('then a row without its own date inherits the date above it', () {
      final sameDay = meetings.where(
        (meeting) => meeting.date == DateTime(2026, 9, 30),
      );
      expect(sameDay.map((meeting) => meeting.title), [
        'Sozial-, Bildungs- und Kulturausschuss',
        'Hauptausschuss',
      ]);
    });

    test('then an announcement is linked with an absolute url', () {
      final document = meetings.first.announcement;
      expect(document, isNotNull);
      expect(document!.id, '186713');
      expect(document.kind, MeetingDocumentKind.announcement);
      expect(document.label, contains('Öffentliche Bekanntmachung'));
      expect(
        document.sourceUrl,
        startsWith('https://www.buergerinfo-langenzenn.de/getfile.php'),
      );
    });

    test('then a meeting without documents cannot be opened', () {
      final withoutDocuments = meetings.firstWhere(
        (meeting) => meeting.id == '3443',
      );
      expect(withoutDocuments.hasDetails, isFalse);
    });
  });

  group('given the minutes tab', () {
    final meetings = parser.parse(fixture('minutes_list.html'));

    test('then both document kinds are attached to the meeting', () {
      final meeting = meetings.firstWhere((meeting) => meeting.id == '3394');
      expect(meeting.announcement?.id, '180977');
      expect(meeting.minutes?.id, '182603');
      expect(meeting.minutes?.kind, MeetingDocumentKind.minutes);
      expect(meeting.hasDetails, isTrue);
    });

    test('then a closed session exposes its end time', () {
      final meeting = meetings.firstWhere((meeting) => meeting.id == '3394');
      expect(meeting.startTime, '17:00');
      expect(meeting.endTime, '18:21');
    });
  });

  group('given html without a session table', () {
    test('then it yields no meetings instead of throwing', () {
      expect(parser.parse('<html><body>nichts</body></html>'), isEmpty);
    });
  });
}
