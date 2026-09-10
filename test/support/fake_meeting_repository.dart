import 'package:council/features/meetings/domain/entities/meeting.dart';
import 'package:council/features/meetings/domain/entities/meeting_detail.dart';
import 'package:council/features/meetings/domain/entities/meeting_document.dart';
import 'package:council/features/meetings/domain/repositories/meeting_repository.dart';

class FakeMeetingRepository implements MeetingRepository {
  FakeMeetingRepository({
    this.meetings = const [],
    this.details = const {},
    this.seenDocumentIds = const {},
    this.failure,
  });

  List<Meeting> meetings;
  Map<String, MeetingDetail> details;
  Set<String> seenDocumentIds;
  Object? failure;

  final List<Set<String>> markedSeen = [];

  @override
  Future<List<Meeting>> loadMeetings() async {
    if (failure != null) throw failure!;
    return meetings;
  }

  @override
  Future<Meeting?> findMeeting(String meetingId) async {
    if (failure != null) throw failure!;
    for (final meeting in meetings) {
      if (meeting.id == meetingId) return meeting;
    }
    return null;
  }

  @override
  Future<MeetingDetail> loadDetail(String meetingId) async {
    if (failure != null) throw failure!;
    final detail = details[meetingId];
    if (detail == null) throw StateError('kein Detail für $meetingId');
    return detail;
  }

  @override
  Future<Set<String>> loadSeenDocumentIds() async => seenDocumentIds;

  @override
  Future<void> markDocumentsSeen(Set<String> documentIds) async {
    markedSeen.add(documentIds);
    seenDocumentIds = documentIds;
  }
}

Meeting buildMeeting({
  String id = '1',
  String title = 'Stadtrat Langenzenn',
  DateTime? date,
  String? startTime = '17:00',
  String? endTime,
  String? location = 'Sitzungssaal',
  String? announcementId,
  String? minutesId,
}) {
  return Meeting(
    id: id,
    title: title,
    date: date ?? DateTime(2026, 1, 13),
    startTime: startTime,
    endTime: endTime,
    location: location,
    announcement: announcementId == null
        ? null
        : MeetingDocument(
            id: announcementId,
            kind: MeetingDocumentKind.announcement,
            label: 'Öffentliche Bekanntmachung',
            sourceUrl: 'https://example.test/$announcementId',
          ),
    minutes: minutesId == null
        ? null
        : MeetingDocument(
            id: minutesId,
            kind: MeetingDocumentKind.minutes,
            label: 'Niederschrift',
            sourceUrl: 'https://example.test/$minutesId',
          ),
  );
}
