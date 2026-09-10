import 'package:equatable/equatable.dart';

import '../../domain/entities/meeting.dart';

enum MeetingsStatus { initial, loading, ready, failure }

class MeetingsState extends Equatable {
  const MeetingsState({
    this.status = MeetingsStatus.initial,
    this.meetings = const [],
    this.newDocumentIds = const {},
    this.isRefreshing = false,
    this.errorMessage,
  });

  final MeetingsStatus status;
  final List<Meeting> meetings;
  final Set<String> newDocumentIds;
  final bool isRefreshing;
  final String? errorMessage;

  bool get isEmpty => status == MeetingsStatus.ready && meetings.isEmpty;

  bool hasNewDocuments(Meeting meeting) =>
      newDocumentIds.contains(meeting.announcement?.id) ||
      newDocumentIds.contains(meeting.minutes?.id);

  MeetingsState copyWith({
    MeetingsStatus? status,
    List<Meeting>? meetings,
    Set<String>? newDocumentIds,
    bool? isRefreshing,
    String? errorMessage,
  }) {
    return MeetingsState(
      status: status ?? this.status,
      meetings: meetings ?? this.meetings,
      newDocumentIds: newDocumentIds ?? this.newDocumentIds,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    meetings,
    newDocumentIds,
    isRefreshing,
    errorMessage,
  ];
}
