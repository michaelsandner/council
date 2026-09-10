import 'package:council/features/meetings/data/parsing/announcement_parser.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/fixtures.dart';

void main() {
  const parser = AnnouncementParser();

  group('given the Werkausschuss announcement', () {
    final announcement = parser.parse(
      fixture('announcement_werkausschuss.txt'),
    );

    test('then it reads the heading and session number', () {
      expect(announcement.heading, '24. Sitzung des Werkausschusses');
      expect(announcement.sessionNumber, 24);
    });

    test('then it reads date, time and location', () {
      expect(announcement.date, DateTime(2024, 1, 25));
      expect(announcement.startTime, '16:00');
      expect(
        announcement.location,
        'Sitzungssaal des Alten Rathauses in Langenzenn, Prinzregentenplatz 1',
      );
    });

    test('then it keeps the agenda numbering of the public items', () {
      expect(announcement.agenda.map((item) => item.number), [
        '3.',
        '4.',
        '5.',
        '6.',
        '6.1.',
        '7.',
      ]);
    });

    test('then it joins an agenda title that wraps across lines', () {
      expect(
        announcement.agenda.first.title,
        'Eventuelle Anpassung der Strompreise im ersten Quartal aufgrund des '
        'möglichen Wegfalls des Bundeszuschusses für die Netzentgelte an die ÜNB',
      );
    });

    test('then it exposes the nesting depth of a sub item', () {
      final subItem = announcement.agenda.firstWhere(
        (item) => item.number == '6.1.',
      );
      expect(subItem.depth, 2);
      expect(announcement.agenda.first.depth, 1);
    });

    test('then it keeps free-standing remarks out of the agenda', () {
      expect(announcement.notes, [
        'Die öffentliche Sitzung beginnt um ca. 16:30 Uhr.',
      ]);
    });

    test('then it reads the closing note and signature', () {
      expect(
        announcement.closingNote,
        startsWith('Die hier fehlenden Tagesordnungspunkte'),
      );
      expect(announcement.issuedOn, '19. Januar 2024');
      expect(announcement.signedBy, 'Habel, Erster Bürgermeister');
    });
  });

  group('given an announcement without a session number', () {
    final announcement = parser.parse(
      fixture('announcement_without_number.txt'),
    );

    test('then the heading is kept and the number stays null', () {
      expect(announcement.heading, 'Sitzung des Redaktionsausschusses');
      expect(announcement.sessionNumber, isNull);
    });

    test('then the location spanning two lines is joined', () {
      expect(
        announcement.location,
        'Rathaus, Friedrich-Ebert-Str. 7, Besprechungsraum im 1. OG',
      );
    });

    test('then the agenda is still read', () {
      expect(announcement.agenda, hasLength(2));
      expect(
        announcement.agenda.last.title,
        'Freigabe aktueller Veröffentlichungen',
      );
    });
  });

  group('given an announcement whose intro ends on "eine öffentliche"', () {
    final announcement = parser.parse(
      fixture('announcement_alternate_intro.txt'),
    );

    test('then the heading is the session, not the first agenda item', () {
      expect(announcement.heading, 'Sitzung des Stadtrates');
    });

    test('then the location does not swallow the trailing article', () {
      expect(
        announcement.location,
        'Sitzungssaal des Alten Rathauses in Langenzenn, Prinzregentenplatz 1',
      );
    });

    test('then date, time and agenda are still read', () {
      expect(announcement.date, DateTime(2023, 2, 9));
      expect(announcement.startTime, '16:00');
      expect(announcement.agenda.first.number, '2.');
      expect(announcement.agenda, hasLength(16));
    });
  });

  group('given text that is not an announcement', () {
    test('then parsing yields an empty result instead of throwing', () {
      final announcement = parser.parse('Völlig anderer Inhalt');
      expect(announcement.heading, isEmpty);
      expect(announcement.agenda, isEmpty);
    });
  });
}
