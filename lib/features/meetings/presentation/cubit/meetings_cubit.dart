import 'package:bloc/bloc.dart';

import '../../domain/entities/meeting.dart';
import '../../domain/repositories/meeting_repository.dart';
import 'meeting_filter.dart';
import 'meetings_state.dart';

class MeetingsCubit extends Cubit<MeetingsState> {
  MeetingsCubit(this._repository) : super(const MeetingsState());

  final MeetingRepository _repository;

  Future<void> load() => _fetch(showSpinner: true);

  Future<void> refresh() => _fetch(showSpinner: false);

  void selectFilter(MeetingFilter filter) =>
      emit(state.copyWith(filter: filter));

  Future<void> _fetch({required bool showSpinner}) async {
    if (state.isRefreshing) return;
    emit(
      state.copyWith(
        status: showSpinner ? MeetingsStatus.loading : state.status,
        isRefreshing: true,
      ),
    );

    try {
      final meetings = await _repository.loadMeetings();
      final seen = await _repository.loadSeenDocumentIds();
      final published = _documentIdsOf(meetings);

      emit(
        state.copyWith(
          status: MeetingsStatus.ready,
          meetings: meetings,
          newDocumentIds: seen.isEmpty ? const {} : published.difference(seen),
          isRefreshing: false,
        ),
      );
      await _repository.markDocumentsSeen(published);
    } catch (error) {
      emit(
        state.copyWith(
          status: state.meetings.isEmpty
              ? MeetingsStatus.failure
              : MeetingsStatus.ready,
          isRefreshing: false,
          errorMessage: '$error',
        ),
      );
    }
  }

  Set<String> _documentIdsOf(List<Meeting> meetings) => {
    for (final meeting in meetings) ...[
      if (meeting.announcement != null) meeting.announcement!.id,
      if (meeting.minutes != null) meeting.minutes!.id,
    ],
  };
}
