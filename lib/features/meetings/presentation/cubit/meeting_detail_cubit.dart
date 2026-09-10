import 'package:bloc/bloc.dart';

import '../../domain/entities/meeting.dart';
import '../../domain/repositories/meeting_repository.dart';
import 'meeting_detail_state.dart';

class MeetingDetailCubit extends Cubit<MeetingDetailState> {
  MeetingDetailCubit(this._repository) : super(const MeetingDetailState());

  final MeetingRepository _repository;

  /// [known] short-circuits the index lookup when the list already had the
  /// meeting; a deep link or a reload arrives without it.
  Future<void> load(String meetingId, {Meeting? known}) async {
    emit(MeetingDetailState(meeting: known));
    try {
      final meeting = known ?? await _repository.findMeeting(meetingId);
      if (meeting == null) {
        emit(const MeetingDetailState(status: MeetingDetailStatus.notFound));
        return;
      }
      final detail = await _repository.loadDetail(meetingId);
      emit(
        MeetingDetailState(
          status: MeetingDetailStatus.ready,
          meeting: meeting,
          detail: detail,
        ),
      );
    } catch (error) {
      emit(
        MeetingDetailState(
          status: MeetingDetailStatus.failure,
          meeting: known,
          errorMessage: '$error',
        ),
      );
    }
  }
}
