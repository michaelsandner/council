import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/formatting/german_date.dart';
import '../../domain/entities/meeting.dart';
import '../../domain/entities/meeting_detail.dart';
import '../cubit/meeting_detail_cubit.dart';
import '../cubit/meeting_detail_state.dart';
import '../widgets/announcement_view.dart';
import '../widgets/minutes_view.dart';

class MeetingDetailPage extends StatefulWidget {
  const MeetingDetailPage({required this.meetingId, this.meeting, super.key});

  final String meetingId;
  final Meeting? meeting;

  @override
  State<MeetingDetailPage> createState() => _MeetingDetailPageState();
}

class _MeetingDetailPageState extends State<MeetingDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MeetingDetailCubit>().load(
        widget.meetingId,
        known: widget.meeting,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MeetingDetailCubit, MeetingDetailState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: Text(state.meeting?.title ?? 'Sitzung')),
          body: switch (state.status) {
            MeetingDetailStatus.loading => const Center(
              child: CircularProgressIndicator(),
            ),
            MeetingDetailStatus.notFound => const _Message(
              text: 'Diese Sitzung wurde nicht gefunden.',
            ),
            MeetingDetailStatus.failure => _Message(
              text:
                  state.errorMessage ??
                  'Die Details konnten nicht geladen werden.',
            ),
            MeetingDetailStatus.ready => _DetailBody(
              meeting: state.meeting!,
              detail: state.detail!,
            ),
          },
        );
      },
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.meeting, required this.detail});

  final Meeting meeting;
  final MeetingDetail detail;

  @override
  Widget build(BuildContext context) {
    final minutes = detail.minutes;
    final announcement = detail.announcement;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
      children: [
        _Header(meeting: meeting, isMinutes: minutes != null),
        const SizedBox(height: 16),
        if (minutes != null)
          MinutesView(minutes: minutes)
        else if (announcement != null)
          AnnouncementView(announcement: announcement)
        else
          const Center(child: Text('Keine Inhalte vorhanden.')),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(text, textAlign: TextAlign.center),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.meeting, required this.isMinutes});

  final Meeting meeting;
  final bool isMinutes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time = formatTimeRange(meeting.startTime, meeting.endTime);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isMinutes ? 'NIEDERSCHRIFT' : 'ÖFFENTLICHE BEKANNTMACHUNG',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          formatFullDate(meeting.date),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (time.isNotEmpty)
          Text(
            time,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        if (meeting.location != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              meeting.location!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}
