import 'package:flutter/material.dart';

import '../../domain/entities/announcement.dart';
import 'section_card.dart';

class AnnouncementView extends StatelessWidget {
  const AnnouncementView({required this.announcement, super.key});

  final Announcement announcement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final note in announcement.notes) ...[
          SectionCard(child: Text(note, style: theme.textTheme.bodyMedium)),
          const SizedBox(height: 12),
        ],
        Text(
          'Tagesordnung',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        for (final item in announcement.agenda) ...[
          SectionCard(
            padding: EdgeInsets.only(left: 12.0 * (item.depth - 1) + 16),
            child: Row(
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
                  child: Text(item.title, style: theme.textTheme.bodyMedium),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (announcement.closingNote != null) ...[
          const SizedBox(height: 8),
          Text(
            announcement.closingNote!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (announcement.issuedOn != null) ...[
          const SizedBox(height: 12),
          Text(
            [
              'Langenzenn, ${announcement.issuedOn}',
              if (announcement.signedBy != null) announcement.signedBy,
            ].join(' · '),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
