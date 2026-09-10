import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/formatting/german_date.dart';
import '../../domain/entities/meeting.dart';
import '../cubit/meetings_cubit.dart';
import '../cubit/meetings_state.dart';
import '../widgets/meeting_filter_bar.dart';
import '../widgets/meeting_list_tile.dart';

class MeetingsPage extends StatefulWidget {
  const MeetingsPage({required this.onOpenMeeting, super.key});

  final void Function(Meeting meeting) onOpenMeeting;

  @override
  State<MeetingsPage> createState() => _MeetingsPageState();
}

class _MeetingsPageState extends State<MeetingsPage> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _refreshOnResume);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MeetingsCubit>().load();
    });
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _refreshOnResume() {
    if (!mounted) return;
    context.read<MeetingsCubit>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stadtrat Langenzenn'),
        bottom: const _RefreshIndicatorLine(),
      ),
      body: BlocBuilder<MeetingsCubit, MeetingsState>(
        builder: (context, state) {
          return switch (state.status) {
            MeetingsStatus.initial || MeetingsStatus.loading => const Center(
              child: CircularProgressIndicator(),
            ),
            MeetingsStatus.failure => _FailureView(
              message: state.errorMessage ?? 'Unbekannter Fehler',
              onRetry: () => context.read<MeetingsCubit>().load(),
            ),
            MeetingsStatus.ready => _MeetingsList(
              state: state,
              onOpenMeeting: widget.onOpenMeeting,
            ),
          };
        },
      ),
    );
  }
}

class _RefreshIndicatorLine extends StatelessWidget
    implements PreferredSizeWidget {
  const _RefreshIndicatorLine();

  @override
  Size get preferredSize => const Size.fromHeight(2);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MeetingsCubit, MeetingsState>(
      buildWhen: (previous, current) =>
          previous.isRefreshing != current.isRefreshing,
      builder: (context, state) => SizedBox(
        height: 2,
        child: state.isRefreshing && state.meetings.isNotEmpty
            ? const LinearProgressIndicator(minHeight: 2)
            : null,
      ),
    );
  }
}

class _MeetingsList extends StatelessWidget {
  const _MeetingsList({required this.state, required this.onOpenMeeting});

  final MeetingsState state;
  final void Function(Meeting meeting) onOpenMeeting;

  @override
  Widget build(BuildContext context) {
    if (state.isEmpty) {
      return const _Refreshable(
        child: _EmptyView('Noch keine Sitzungen vorhanden.'),
      );
    }
    final meetings = state.visibleMeetings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MeetingFilterBar(
          selected: state.filter,
          onSelect: context.read<MeetingsCubit>().selectFilter,
        ),
        Expanded(
          child: _Refreshable(
            child: meetings.isEmpty
                ? const _EmptyView('Keine Sitzungen für diesen Filter.')
                : _MeetingsListView(
                    meetings: meetings,
                    state: state,
                    onOpenMeeting: onOpenMeeting,
                  ),
          ),
        ),
      ],
    );
  }
}

class _Refreshable extends StatelessWidget {
  const _Refreshable({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<MeetingsCubit>().refresh(),
      child: child,
    );
  }
}

class _MeetingsListView extends StatelessWidget {
  const _MeetingsListView({
    required this.meetings,
    required this.state,
    required this.onOpenMeeting,
  });

  final List<Meeting> meetings;
  final MeetingsState state;
  final void Function(Meeting meeting) onOpenMeeting;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      itemCount: meetings.length,
      separatorBuilder: (context, index) => _separatorFor(index),
      itemBuilder: (context, index) {
        final meeting = meetings[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (index == 0) _MonthHeading(date: meeting.date),
            MeetingListTile(
              meeting: meeting,
              hasNewDocuments: state.hasNewDocuments(meeting),
              onTap: () => onOpenMeeting(meeting),
            ),
          ],
        );
      },
    );
  }

  Widget _separatorFor(int index) {
    final current = meetings[index].date;
    final next = meetings[index + 1].date;
    final sameMonth = current.year == next.year && current.month == next.month;
    return sameMonth ? const SizedBox(height: 8) : _MonthHeading(date: next);
  }
}

class _MonthHeading extends StatelessWidget {
  const _MonthHeading({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        formatMonth(date),
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Center(child: Text(message, textAlign: TextAlign.center)),
      ],
    );
  }
}

class _FailureView extends StatelessWidget {
  const _FailureView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 40,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      ),
    );
  }
}
