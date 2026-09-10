import '../../domain/entities/meeting.dart';

enum MeetingFilter {
  all,
  minutes,
  agenda;

  bool matches(Meeting meeting) => switch (this) {
    MeetingFilter.all => true,
    MeetingFilter.minutes => meeting.hasMinutes,
    MeetingFilter.agenda => meeting.hasAnnouncement,
  };
}
