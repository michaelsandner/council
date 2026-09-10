import '../entities/meeting.dart';
import '../entities/meeting_detail.dart';

abstract class MeetingRepository {
  Future<List<Meeting>> loadMeetings();

  Future<MeetingDetail> loadDetail(String meetingId);

  Future<Set<String>> loadSeenDocumentIds();

  Future<void> markDocumentsSeen(Set<String> documentIds);
}
