import 'dart:convert';

import 'package:council/features/meetings/data/datasources/council_data_source.dart';
import 'package:council/features/meetings/data/repositories/meeting_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  MeetingRepositoryImpl buildRepository(
    Map<String, Object> responses, {
    int statusCode = 200,
  }) {
    final client = MockClient((request) async {
      final path = request.url.path;
      final key = responses.keys.firstWhere(
        (candidate) => path.endsWith(candidate),
        orElse: () => '',
      );
      if (key.isEmpty) return http.Response('not found', 404);
      return http.Response(
        jsonEncode(responses[key]),
        statusCode,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });

    return MeetingRepositoryImpl(
      dataSource: CouncilDataSource(
        httpClient: client,
        baseUri: Uri.parse('https://example.test/council/'),
      ),
    );
  }

  group('given a published index', () {
    final repository = buildRepository({
      'data/index.json': {
        'generatedAt': '2026-09-10T06:00:00Z',
        'meetings': [
          {'id': '1', 'title': 'Werkausschuss', 'date': '2026-01-13'},
          {
            'id': '2',
            'title': 'Stadtrat Langenzenn',
            'date': '2026-03-18',
            'startTime': '17:00',
            'endTime': '18:21',
            'location': 'Sitzungssaal',
            'minutes': {
              'id': 'ni-2',
              'kind': 'minutes',
              'label': 'Niederschrift',
              'sourceUrl': 'https://example.test/ni-2',
            },
          },
        ],
      },
    });

    test('then the meetings are returned newest first', () async {
      final meetings = await repository.loadMeetings();
      expect(meetings.map((meeting) => meeting.id), ['2', '1']);
    });

    test('then optional fields survive the round trip', () async {
      final meetings = await repository.loadMeetings();
      final stadtrat = meetings.first;
      expect(stadtrat.endTime, '18:21');
      expect(stadtrat.location, 'Sitzungssaal');
      expect(stadtrat.minutes?.id, 'ni-2');
      expect(stadtrat.hasMinutes, isTrue);
      expect(stadtrat.hasAnnouncement, isFalse);
    });

    test('then a meeting can be found by id', () async {
      final meeting = await repository.findMeeting('1');
      expect(meeting?.title, 'Werkausschuss');
      expect(await repository.findMeeting('nope'), isNull);
    });
  });

  group('given a published detail', () {
    final repository = buildRepository({
      'data/meetings/2.json': {
        'meetingId': '2',
        'minutes': {
          'heading': '88. Sitzung des Stadtrates',
          'items': [
            {
              'number': '5.',
              'title': 'Bauantrag',
              'facts': 'Sachverhalt',
              'vote': {'summary': 'beschlossen', 'inFavour': 12, 'against': 9},
            },
          ],
        },
      },
    });

    test('then the minutes and its vote are decoded', () async {
      final detail = await repository.loadDetail('2');
      expect(detail.minutes?.heading, '88. Sitzung des Stadtrates');
      expect(detail.minutes?.items.single.vote?.inFavour, 12);
      expect(detail.announcement, isNull);
    });
  });

  group('given the data is unavailable', () {
    test('then loading reports a readable error', () async {
      final repository = buildRepository(const {});
      expect(
        () => repository.loadMeetings(),
        throwsA(isA<CouncilDataException>()),
      );
    });
  });
}
