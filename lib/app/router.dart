import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../features/meetings/domain/entities/meeting.dart';
import '../features/meetings/domain/repositories/meeting_repository.dart';
import '../features/meetings/presentation/cubit/meeting_detail_cubit.dart';
import '../features/meetings/presentation/cubit/meetings_cubit.dart';
import '../features/meetings/presentation/pages/meeting_detail_page.dart';
import '../features/meetings/presentation/pages/meetings_page.dart';

GoRouter buildRouter(MeetingRepository repository) {
  return GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => BlocProvider(
          create: (_) => MeetingsCubit(repository),
          child: MeetingsPage(
            onOpenMeeting: (meeting) =>
                context.push('/sitzung/${meeting.id}', extra: meeting),
          ),
        ),
      ),
      GoRoute(
        path: '/sitzung/:id',
        builder: (context, state) => BlocProvider(
          create: (_) => MeetingDetailCubit(repository),
          child: MeetingDetailPage(
            meetingId: state.pathParameters['id']!,
            meeting: state.extra as Meeting?,
          ),
        ),
      ),
    ],
  );
}
