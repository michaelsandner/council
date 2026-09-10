import 'package:flutter/material.dart';

import '../../domain/entities/attendance.dart';
import '../../domain/entities/minutes.dart';
import '../../domain/entities/vote_result.dart';
import 'section_card.dart';

class MinutesView extends StatelessWidget {
  const MinutesView({required this.minutes, super.key});

  final Minutes minutes;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (minutes.present.isNotEmpty)
          _AttendanceCard(title: 'Anwesend', groups: minutes.present),
        if (minutes.absent.isNotEmpty) ...[
          const SizedBox(height: 12),
          _AttendanceCard(
            title: 'Abwesend / Entschuldigt',
            groups: minutes.absent,
          ),
        ],
        const SizedBox(height: 20),
        Text(
          'Tagesordnung',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        for (final item in minutes.items) ...[
          _MinutesItemCard(item: item),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _MinutesItemCard extends StatelessWidget {
  const _MinutesItemCard({required this.item});

  final MinutesItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      padding: EdgeInsets.only(left: 12.0 * (item.depth - 1) + 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 44,
                child: Text(
                  item.number,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  item.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (item.facts != null) ...[
            const SizedBox(height: 10),
            _Block(label: 'Sachverhalt', text: item.facts!),
          ],
          if (item.decision != null) ...[
            const SizedBox(height: 10),
            _Block(label: 'Beschluss', text: item.decision!),
          ],
          if (item.vote != null) ...[
            const SizedBox(height: 10),
            _VoteChip(vote: item.vote!),
          ],
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 2),
        SelectableText(text, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

class _VoteChip extends StatelessWidget {
  const _VoteChip({required this.vote});

  final VoteResult vote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final counts = [
      if (vote.inFavour != null) 'Dafür ${vote.inFavour}',
      if (vote.against != null) 'Dagegen ${vote.against}',
      if (vote.present != null) 'Anwesend ${vote.present}',
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.how_to_vote_outlined,
            size: 16,
            color: theme.colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              counts.isEmpty ? vote.summary : '${vote.summary} · $counts',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard({required this.title, required this.groups});

  final String title;
  final List<AttendanceGroup> groups;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          for (final group in groups) ...[
            const SizedBox(height: 8),
            Text(
              group.role,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            for (final member in group.members)
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Text(
                  member.note == null
                      ? member.name
                      : '${member.name} — ${member.note}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
          ],
        ],
      ),
    );
  }
}
