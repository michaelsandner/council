import 'package:council/features/meetings/domain/entities/agenda_item.dart';
import 'package:council/features/meetings/domain/entities/announcement.dart';
import 'package:council/features/meetings/domain/entities/meeting_detail.dart';
import 'package:council/features/meetings/domain/entities/minutes.dart';
import 'package:council/features/meetings/domain/entities/vote_result.dart';
import 'package:council/features/meetings/presentation/cubit/meeting_detail_cubit.dart';
import 'package:council/features/meetings/presentation/pages/meeting_detail_page.dart';
import 'package:council/features/meetings/presentation/widgets/announcement_view.dart';
import 'package:council/features/meetings/presentation/widgets/minutes_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../../../support/fake_meeting_repository.dart';

void main() {
  setUpAll(() => initializeDateFormatting('de_DE'));

  const announcement = Announcement(
    heading: '24. Sitzung des Werkausschusses',
    agenda: [AgendaItem(number: '3.', title: 'Anpassung der Strompreise')],
    notes: ['Die öffentliche Sitzung beginnt um ca. 16:30 Uhr.'],
  );

  const minutes = Minutes(
    heading: '88. Sitzung des Stadtrates',
    items: [
      MinutesItem(
        number: '5.',
        title: 'Antrag auf Verlängerung der Baugenehmigung',
        facts: 'Das Landratsamt hat um Rückmeldung gebeten.',
        decision: 'Das Einvernehmen wird nicht erteilt.',
        vote: VoteResult(
          summary: 'mehrheitlich beschlossen',
          inFavour: 12,
          against: 9,
        ),
      ),
    ],
  );

  Future<void> pumpDetail(
    WidgetTester tester,
    FakeMeetingRepository repository,
    String meetingId,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => MeetingDetailCubit(repository),
          child: MeetingDetailPage(meetingId: meetingId),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('given a meeting with minutes and an announcement', () {
    testWidgets('then the minutes are shown', (tester) async {
      final repository = FakeMeetingRepository(
        meetings: [
          buildMeeting(id: '1', minutesId: 'ni', announcementId: 'bm'),
        ],
        details: {
          '1': const MeetingDetail(
            meetingId: '1',
            announcement: announcement,
            minutes: minutes,
          ),
        },
      );

      await pumpDetail(tester, repository, '1');

      expect(find.byType(MinutesView), findsOneWidget);
      expect(find.byType(AnnouncementView), findsNothing);
      expect(find.text('NIEDERSCHRIFT'), findsOneWidget);
    });

    testWidgets('then facts, decision and vote are rendered', (tester) async {
      final repository = FakeMeetingRepository(
        meetings: [buildMeeting(id: '1', minutesId: 'ni')],
        details: {'1': const MeetingDetail(meetingId: '1', minutes: minutes)},
      );

      await pumpDetail(tester, repository, '1');

      expect(find.text('Sachverhalt'), findsOneWidget);
      expect(find.text('Beschluss'), findsOneWidget);
      expect(
        find.text('mehrheitlich beschlossen · Dafür 12 · Dagegen 9'),
        findsOneWidget,
      );
    });
  });

  group('given a meeting with only an announcement', () {
    testWidgets('then the announcement is shown instead', (tester) async {
      final repository = FakeMeetingRepository(
        meetings: [buildMeeting(id: '2', announcementId: 'bm')],
        details: {
          '2': const MeetingDetail(meetingId: '2', announcement: announcement),
        },
      );

      await pumpDetail(tester, repository, '2');

      expect(find.byType(AnnouncementView), findsOneWidget);
      expect(find.byType(MinutesView), findsNothing);
      expect(find.text('ÖFFENTLICHE BEKANNTMACHUNG'), findsOneWidget);
      expect(find.text('Anpassung der Strompreise'), findsOneWidget);
    });
  });

  group('given a deep link to an unknown meeting', () {
    testWidgets('then a not-found message is shown', (tester) async {
      final repository = FakeMeetingRepository(meetings: []);

      await pumpDetail(tester, repository, 'missing');

      expect(find.text('Diese Sitzung wurde nicht gefunden.'), findsOneWidget);
    });
  });

  group('given a deep link without the meeting in hand', () {
    testWidgets('then the meeting is resolved from the index', (tester) async {
      final repository = FakeMeetingRepository(
        meetings: [
          buildMeeting(id: '3', title: 'Werkausschuss', minutesId: 'ni'),
        ],
        details: {'3': const MeetingDetail(meetingId: '3', minutes: minutes)},
      );

      await pumpDetail(tester, repository, '3');

      expect(find.text('Werkausschuss'), findsOneWidget);
      expect(find.byType(MinutesView), findsOneWidget);
    });
  });
}
