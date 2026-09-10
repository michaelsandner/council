import '../../domain/entities/meeting.dart';
import '../../domain/entities/meeting_detail.dart';
import '../../domain/repositories/meeting_repository.dart';
import '../datasources/council_data_source.dart';
import '../datasources/seen_documents_store.dart';
import '../dtos/meeting_detail_json.dart';
import '../dtos/meeting_json.dart';

class MeetingRepositoryImpl implements MeetingRepository {
  const MeetingRepositoryImpl({
    required this.dataSource,
    this.seenDocuments = const SeenDocumentsStore(),
  });

  final CouncilDataSource dataSource;
  final SeenDocumentsStore seenDocuments;

  @override
  Future<List<Meeting>> loadMeetings() async {
    final json = await dataSource.fetchIndex();
    final meetings = (json['meetings'] as List<dynamic>? ?? const [])
        .map((entry) => meetingFromJson(entry as Map<String, dynamic>))
        .toList();
    return meetings..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<Meeting?> findMeeting(String meetingId) async {
    final meetings = await loadMeetings();
    for (final meeting in meetings) {
      if (meeting.id == meetingId) return meeting;
    }
    return null;
  }

  @override
  Future<MeetingDetail> loadDetail(String meetingId) async {
    final json = await dataSource.fetchDetail(meetingId);
    return meetingDetailFromJson(json);
  }

  @override
  Future<Set<String>> loadSeenDocumentIds() => seenDocuments.load();

  @override
  Future<void> markDocumentsSeen(Set<String> documentIds) =>
      seenDocuments.save(documentIds);
}
