import 'package:council/features/meetings/domain/entities/meeting.dart';
import 'package:council/features/meetings/presentation/cubit/meetings_cubit.dart';
import 'package:council/features/meetings/presentation/pages/meetings_page.dart';
import 'package:council/features/meetings/presentation/widgets/document_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../../../support/fake_meeting_repository.dart';

void main() {
  setUpAll(() => initializeDateFormatting('de_DE'));

  Future<List<Meeting>> pumpPage(
    WidgetTester tester,
    FakeMeetingRepository repository,
  ) async {
    final opened = <Meeting>[];
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => MeetingsCubit(repository),
          child: MeetingsPage(onOpenMeeting: opened.add),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return opened;
  }

  Finder inList(String text) =>
      find.descendant(of: find.byType(ListView), matching: find.text(text));

  group('given meetings with different documents', () {
    late FakeMeetingRepository repository;

    setUp(() {
      repository = FakeMeetingRepository(
        meetings: [
          buildMeeting(
            id: 'with-minutes',
            title: 'Stadtrat Langenzenn',
            date: DateTime(2026, 3, 18),
            minutesId: 'ni-1',
            announcementId: 'bm-1',
          ),
          buildMeeting(
            id: 'announcement-only',
            title: 'Werkausschuss',
            date: DateTime(2026, 2, 10),
            announcementId: 'bm-2',
          ),
          buildMeeting(
            id: 'no-documents',
            title: 'Hauptausschuss',
            date: DateTime(2026, 1, 5),
          ),
        ],
      );
    });

    testWidgets('then every meeting is listed', (tester) async {
      await pumpPage(tester, repository);

      expect(inList('Stadtrat Langenzenn'), findsOneWidget);
      expect(inList('Werkausschuss'), findsOneWidget);
      expect(inList('Hauptausschuss'), findsOneWidget);
    });

    testWidgets('then minutes and announcements are marked differently', (
      tester,
    ) async {
      await pumpPage(tester, repository);

      expect(find.text('Niederschrift'), findsOneWidget);
      expect(find.text('Bekanntmachung'), findsNWidgets(2));
      expect(find.byType(DocumentBadge), findsNWidgets(3));
    });

    testWidgets('then a meeting without documents shows no badge', (
      tester,
    ) async {
      await pumpPage(tester, repository);

      final tile = find.ancestor(
        of: find.text('Hauptausschuss'),
        matching: find.byType(ListTile),
      );
      expect(
        find.descendant(of: tile, matching: find.byType(DocumentBadge)),
        findsNothing,
      );
    });

    testWidgets('then tapping a meeting with minutes opens it', (tester) async {
      final opened = await pumpPage(tester, repository);

      await tester.tap(inList('Stadtrat Langenzenn'));
      await tester.pumpAndSettle();

      expect(opened.single.id, 'with-minutes');
    });

    testWidgets('then tapping a meeting with only an announcement opens it', (
      tester,
    ) async {
      final opened = await pumpPage(tester, repository);

      await tester.tap(inList('Werkausschuss'));
      await tester.pumpAndSettle();

      expect(opened.single.id, 'announcement-only');
    });

    testWidgets('then a meeting without documents cannot be opened', (
      tester,
    ) async {
      final opened = await pumpPage(tester, repository);

      await tester.tap(inList('Hauptausschuss'));
      await tester.pumpAndSettle();

      expect(opened, isEmpty);
    });

    testWidgets('then the month of the meetings is shown as a heading', (
      tester,
    ) async {
      await pumpPage(tester, repository);

      expect(find.text('März 2026'), findsOneWidget);
      expect(find.text('Februar 2026'), findsOneWidget);
      expect(find.text('Januar 2026'), findsOneWidget);
    });
  });

  group('given a new document since the last visit', () {
    testWidgets('then the meeting is marked as new', (tester) async {
      final repository = FakeMeetingRepository(
        meetings: [buildMeeting(id: '1', minutesId: 'ni-1')],
        seenDocumentIds: {'other'},
      );
      await pumpPage(tester, repository);

      final badge = tester.widget<DocumentBadge>(find.byType(DocumentBadge));
      expect(badge.isNew, isTrue);
    });
  });

  group('given the data cannot be loaded', () {
    testWidgets('then the error is shown with a retry action', (tester) async {
      final repository = FakeMeetingRepository(failure: Exception('offline'));
      await pumpPage(tester, repository);

      expect(find.textContaining('offline'), findsOneWidget);
      expect(find.text('Erneut versuchen'), findsOneWidget);
    });
  });

  group('given the list is pulled down', () {
    testWidgets('then the meetings are fetched again', (tester) async {
      final repository = FakeMeetingRepository(
        meetings: [buildMeeting(id: '1', minutesId: 'ni-1')],
      );
      await pumpPage(tester, repository);
      expect(repository.markedSeen, hasLength(1));

      await tester.fling(find.byType(ListView), const Offset(0, 320), 1000);
      await tester.pumpAndSettle();

      expect(repository.markedSeen.length, greaterThan(1));
    });
  });
}
