import 'package:equatable/equatable.dart';

import 'meeting_document.dart';

class Meeting extends Equatable {
  const Meeting({
    required this.id,
    required this.title,
    required this.date,
    this.startTime,
    this.endTime,
    this.location,
    this.announcement,
    this.minutes,
  });

  final String id;
  final String title;
  final DateTime date;
  final String? startTime;
  final String? endTime;
  final String? location;
  final MeetingDocument? announcement;
  final MeetingDocument? minutes;

  bool get hasAnnouncement => announcement != null;

  bool get hasMinutes => minutes != null;

  bool get hasDetails => hasAnnouncement || hasMinutes;

  @override
  List<Object?> get props => [
    id,
    title,
    date,
    startTime,
    endTime,
    location,
    announcement,
    minutes,
  ];
}
