import 'package:council/features/meetings/data/parsing/minutes_parser.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/fixtures.dart';

void main() {
  const parser = MinutesParser();

  group('given the Stadtrat minutes', () {
    final minutes = parser.parse(fixture('minutes_stadtrat.txt'));

    test('then it reads the heading and session number', () {
      expect(minutes.heading, '88. Sitzung des Stadtrates');
      expect(minutes.sessionNumber, 88);
    });

    test('then it reads the schedule, including the label without a colon', () {
      expect(minutes.date, DateTime(2026, 1, 13));
      expect(minutes.startTime, '17:00');
      expect(minutes.endTime, '18:21');
    });

    test('then it joins the location that wraps across lines', () {
      expect(
        minutes.location,
        'Sitzungssaal des Alten Rathauses in Langenzenn, Prinzregentenplatz 1',
      );
    });

    test('then it groups the attendees by their role', () {
      expect(
        minutes.present.map((group) => '${group.role}:${group.members.length}'),
        [
          'Erster Bürgermeister:1',
          'Zweiter Bürgermeister:1',
          'Stadtratsmitglieder:19',
        ],
      );
      expect(minutes.absent.single.role, 'Stadtratsmitglieder');
      expect(minutes.absent.single.members, hasLength(4));
    });

    test('then it keeps the remark column of an attendee', () {
      final mayor = minutes.present.first.members.single;
      expect(mayor.name, 'Habel, Jürgen');
      expect(mayor.note, 'bis Ende TOP 8');
    });

    test('then it reads the agenda items of the public part', () {
      expect(minutes.items.map((item) => item.number), [
        '2.',
        '3.',
        '4.',
        '5.',
        '6.',
        '6.1.',
        '7.',
        '7.1.',
      ]);
    });

    test('then it separates facts from the decision', () {
      final item = minutes.items.firstWhere((item) => item.number == '5.');
      expect(item.facts, contains('Landratsamt Fürth'));
      expect(
        item.decision,
        contains('gemeindliche Einvernehmen wird weiterhin nicht'),
      );
    });

    test('then it reads the vote counts out of the decision', () {
      final item = minutes.items.firstWhere((item) => item.number == '5.');
      expect(item.vote?.summary, 'mehrheitlich beschlossen');
      expect(item.vote?.inFavour, 12);
      expect(item.vote?.against, 9);
      expect(item.vote?.hasCounts, isTrue);
    });

    test('then the vote line is not repeated inside the decision text', () {
      final item = minutes.items.firstWhere((item) => item.number == '5.');
      expect(item.decision, isNot(contains('Dafür:')));
    });

    test('then a deferred item keeps its summary', () {
      final item = minutes.items.firstWhere((item) => item.number == '4.');
      expect(item.vote?.summary, 'vertagt');
      expect(item.vote?.inFavour, 18);
      expect(item.vote?.against, 3);
    });

    test('then a session quoted inside the body is not read as an item', () {
      expect(minutes.items.map((item) => item.number), isNot(contains('64.')));
      expect(
        minutes.items.firstWhere((item) => item.number == '2.').facts,
        contains('64. Sitzung des'),
      );
    });

    test('then page footers are not part of any item text', () {
      for (final item in minutes.items) {
        expect(item.facts ?? '', isNot(contains('Seite ')));
        expect(item.title, isNot(contains('Seite ')));
      }
    });
  });

  group('given minutes without an attendance list', () {
    final minutes = parser.parse(fixture('minutes_without_attendance.txt'));

    test('then the attendance stays empty', () {
      expect(minutes.present, isEmpty);
      expect(minutes.absent, isEmpty);
    });

    test('then the schedule is still read', () {
      expect(minutes.startTime, '16:00');
      expect(minutes.endTime, '17:30');
    });

    test(
      'then body prose starting with a field label does not overwrite it',
      () {
        expect(minutes.endTime, isNot('November'));
        expect(minutes.items, isNotEmpty);
      },
    );

    test('then an item shifted by a page break is still recognised', () {
      expect(minutes.items.map((item) => item.number), contains('6.1.'));
    });
  });

  group('given a decision containing an enumerated list', () {
    final minutes = parser.parse(
      fixture('minutes_with_enumerated_decision.txt'),
    );

    test('then the enumeration does not become an agenda item', () {
      expect(minutes.items.map((item) => item.number), ['12.', '13.']);
    });

    test('then the enumeration stays inside the section it belongs to', () {
      final item = minutes.items.first;
      expect(item.facts, contains('Die Verwaltung wird beauftragt'));
      expect(item.facts, contains('Sollte diese Variante'));
      expect(item.decision, startsWith('Der Stadtrat stimmt der Standort'));
      expect(item.vote?.inFavour, 21);
    });

    test('then the item title stays a title', () {
      expect(
        minutes.items.first.title,
        'Standortfestlegung zum Neubau der Staatlichen Realschule Langenzenn '
        'durch den Landkreis Fürth',
      );
      for (final item in minutes.items) {
        expect(item.title, isNot(contains('Die Verwaltung wird beauftragt')));
      }
    });
  });

  group('given text that is not a minutes document', () {
    test('then parsing yields an empty result instead of throwing', () {
      final minutes = parser.parse('Kein Protokoll');
      expect(minutes.heading, isEmpty);
      expect(minutes.items, isEmpty);
    });
  });
}
