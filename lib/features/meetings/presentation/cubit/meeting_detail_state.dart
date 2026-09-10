import 'package:equatable/equatable.dart';

import '../../domain/entities/meeting.dart';
import '../../domain/entities/meeting_detail.dart';

enum MeetingDetailStatus { loading, ready, notFound, failure }

class MeetingDetailState extends Equatable {
  const MeetingDetailState({
    this.status = MeetingDetailStatus.loading,
    this.meeting,
    this.detail,
    this.errorMessage,
  });

  final MeetingDetailStatus status;
  final Meeting? meeting;
  final MeetingDetail? detail;
  final String? errorMessage;

  bool get showsMinutes => detail?.minutes != null;

  @override
  List<Object?> get props => [status, meeting, detail, errorMessage];
}
