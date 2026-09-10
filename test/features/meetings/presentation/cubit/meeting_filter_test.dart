import 'package:council/features/meetings/presentation/cubit/meeting_filter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/fake_meeting_repository.dart';

void main() {
  group('given a meeting with minutes and an announcement', () {
    final meeting = buildMeeting(minutesId: 'ni', announcementId: 'bm');

    test('then every filter matches', () {
      for (final filter in MeetingFilter.values) {
        expect(filter.matches(meeting), isTrue, reason: filter.name);
      }
    });
  });

  group('given a meeting with only an announcement', () {
    final meeting = buildMeeting(announcementId: 'bm');

    test('then the minutes filter does not match', () {
      expect(MeetingFilter.all.matches(meeting), isTrue);
      expect(MeetingFilter.minutes.matches(meeting), isFalse);
      expect(MeetingFilter.agenda.matches(meeting), isTrue);
    });
  });

  group('given a meeting without documents', () {
    final meeting = buildMeeting();

    test('then only the all filter matches', () {
      expect(MeetingFilter.all.matches(meeting), isTrue);
      expect(MeetingFilter.minutes.matches(meeting), isFalse);
      expect(MeetingFilter.agenda.matches(meeting), isFalse);
    });
  });
}
