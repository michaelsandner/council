import 'package:council/features/meetings/presentation/cubit/meeting_filter.dart';
import 'package:council/features/meetings/presentation/widgets/meeting_filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<List<MeetingFilter>> pumpBar(
    WidgetTester tester, {
    MeetingFilter selected = MeetingFilter.all,
  }) async {
    final chosen = <MeetingFilter>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MeetingFilterBar(selected: selected, onSelect: chosen.add),
        ),
      ),
    );
    return chosen;
  }

  ChoiceChip chip(WidgetTester tester, String label) =>
      tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, label));

  group('given the all filter is selected', () {
    testWidgets('then every filter is offered', (tester) async {
      await pumpBar(tester);

      expect(find.widgetWithText(ChoiceChip, 'Alle'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Niederschrift'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Tagesordnung'), findsOneWidget);
    });

    testWidgets('then only the all chip is selected', (tester) async {
      await pumpBar(tester);

      expect(chip(tester, 'Alle').selected, isTrue);
      expect(chip(tester, 'Niederschrift').selected, isFalse);
      expect(chip(tester, 'Tagesordnung').selected, isFalse);
    });

    testWidgets('then tapping another filter reports it', (tester) async {
      final chosen = await pumpBar(tester);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Tagesordnung'));

      expect(chosen, [MeetingFilter.agenda]);
    });
  });

  group('given the minutes filter is selected', () {
    testWidgets('then only that chip is selected', (tester) async {
      await pumpBar(tester, selected: MeetingFilter.minutes);

      expect(chip(tester, 'Alle').selected, isFalse);
      expect(chip(tester, 'Niederschrift').selected, isTrue);
    });
  });
}
