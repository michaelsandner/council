import 'package:bloc_test/bloc_test.dart';
import 'package:council/features/meetings/presentation/cubit/meetings_cubit.dart';
import 'package:council/features/meetings/presentation/cubit/meetings_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/fake_meeting_repository.dart';

void main() {
  late FakeMeetingRepository repository;

  setUp(() {
    repository = FakeMeetingRepository(
      meetings: [
        buildMeeting(id: '1', date: DateTime(2026, 1, 13), minutesId: 'ni-1'),
        buildMeeting(
          id: '2',
          date: DateTime(2026, 3, 18),
          announcementId: 'bm-2',
        ),
      ],
    );
  });

  group('given a first visit', () {
    blocTest<MeetingsCubit, MeetingsState>(
      'then the meetings are exposed in the order the repository returns',
      build: () => MeetingsCubit(repository),
      act: (cubit) => cubit.load(),
      verify: (cubit) {
        expect(cubit.state.status, MeetingsStatus.ready);
        expect(cubit.state.meetings.map((meeting) => meeting.id), ['1', '2']);
      },
    );

    blocTest<MeetingsCubit, MeetingsState>(
      'then nothing is marked as new, because everything is new',
      build: () => MeetingsCubit(repository),
      act: (cubit) => cubit.load(),
      verify: (cubit) => expect(cubit.state.newDocumentIds, isEmpty),
    );

    blocTest<MeetingsCubit, MeetingsState>(
      'then the shown documents are remembered',
      build: () => MeetingsCubit(repository),
      act: (cubit) => cubit.load(),
      verify: (cubit) => expect(repository.markedSeen.single, {'ni-1', 'bm-2'}),
    );
  });

  group('given a document that was not there last time', () {
    setUp(() => repository.seenDocumentIds = {'ni-1'});

    blocTest<MeetingsCubit, MeetingsState>(
      'then only the unseen document counts as new',
      build: () => MeetingsCubit(repository),
      act: (cubit) => cubit.load(),
      verify: (cubit) {
        expect(cubit.state.newDocumentIds, {'bm-2'});
        final withNewAnnouncement = cubit.state.meetings.firstWhere(
          (meeting) => meeting.id == '2',
        );
        final alreadySeen = cubit.state.meetings.firstWhere(
          (meeting) => meeting.id == '1',
        );
        expect(cubit.state.hasNewDocuments(withNewAnnouncement), isTrue);
        expect(cubit.state.hasNewDocuments(alreadySeen), isFalse);
      },
    );
  });

  group('given the data cannot be loaded', () {
    setUp(() => repository.failure = Exception('offline'));

    blocTest<MeetingsCubit, MeetingsState>(
      'then the first load reports a failure',
      build: () => MeetingsCubit(repository),
      act: (cubit) => cubit.load(),
      verify: (cubit) {
        expect(cubit.state.status, MeetingsStatus.failure);
        expect(cubit.state.errorMessage, contains('offline'));
      },
    );

    blocTest<MeetingsCubit, MeetingsState>(
      'then a failing refresh keeps the meetings already shown',
      build: () => MeetingsCubit(repository),
      act: (cubit) async {
        repository.failure = null;
        await cubit.load();
        repository.failure = Exception('offline');
        await cubit.refresh();
      },
      verify: (cubit) {
        expect(cubit.state.status, MeetingsStatus.ready);
        expect(cubit.state.meetings, hasLength(2));
        expect(cubit.state.errorMessage, contains('offline'));
      },
    );
  });

  group('given a refresh is already running', () {
    blocTest<MeetingsCubit, MeetingsState>(
      'then the refresh flag is cleared again when it finishes',
      build: () => MeetingsCubit(repository),
      act: (cubit) => cubit.refresh(),
      verify: (cubit) => expect(cubit.state.isRefreshing, isFalse),
    );
  });
}
