import 'dart:convert';
import 'dart:io';

import 'package:council/features/meetings/domain/entities/meeting.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../tool/src/council_archive.dart';

void main() {
  const source = 'https://example.test';
  late Directory root;
  late CouncilArchive archive;

  final meetings = [
    Meeting(id: '1', title: 'Stadtrat Langenzenn', date: DateTime(2026, 1, 13)),
  ];

  setUp(() {
    root = Directory.systemTemp.createTempSync('council_archive');
    archive = CouncilArchive(root);
  });

  tearDown(() => root.deleteSync(recursive: true));

  String generatedAt() {
    final json = jsonDecode(archive.indexFile.readAsStringSync());
    return (json as Map<String, dynamic>)['generatedAt'] as String;
  }

  group('given no index yet', () {
    test('then the first write reports a change', () {
      expect(archive.writeIndex(meetings, source: source), isTrue);
      expect(archive.readMeetings(), meetings);
    });
  });

  group('given an index was written', () {
    setUp(() => archive.writeIndex(meetings, source: source));

    test('then writing the same meetings leaves the file untouched', () async {
      final before = generatedAt();
      await Future<void>.delayed(const Duration(milliseconds: 5));

      expect(archive.writeIndex(meetings, source: source), isFalse);
      expect(generatedAt(), before);
    });

    test('then a changed meeting is written with a new timestamp', () async {
      final before = generatedAt();
      await Future<void>.delayed(const Duration(milliseconds: 5));
      final rescheduled = [
        Meeting(
          id: '1',
          title: 'Stadtrat Langenzenn',
          date: DateTime(2026, 1, 14),
        ),
      ];

      expect(archive.writeIndex(rescheduled, source: source), isTrue);
      expect(generatedAt(), isNot(before));
      expect(archive.readMeetings(), rescheduled);
    });
  });
}
