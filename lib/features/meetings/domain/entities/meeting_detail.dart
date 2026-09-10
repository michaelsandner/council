import 'package:equatable/equatable.dart';

import 'announcement.dart';
import 'minutes.dart';

class MeetingDetail extends Equatable {
  const MeetingDetail({required this.meetingId, this.announcement, this.minutes});

  final String meetingId;
  final Announcement? announcement;
  final Minutes? minutes;

  @override
  List<Object?> get props => [meetingId, announcement, minutes];
}
