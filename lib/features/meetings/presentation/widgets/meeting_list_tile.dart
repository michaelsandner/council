import 'package:flutter/material.dart';

import '../../../../core/formatting/german_date.dart';
import '../../domain/entities/meeting.dart';
import '../../domain/entities/meeting_document.dart';
import 'document_badge.dart';

class MeetingListTile extends StatelessWidget {
  const MeetingListTile({
    required this.meeting,
    required this.hasNewDocuments,
    this.onTap,
    super.key,
  });

  final Meeting meeting;
  final bool hasNewDocuments;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time = formatTimeRange(meeting.startTime, meeting.endTime);

    return Card(
      child: ListTile(
        enabled: meeting.hasDetails,
        onTap: meeting.hasDetails ? onTap : null,
        title: Text(
          meeting.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              [
                formatFullDate(meeting.date),
                if (time.isNotEmpty) time,
              ].join(' · '),
            ),
            if (meeting.location != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  meeting.location!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            if (meeting.hasDetails)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (meeting.hasMinutes)
                      DocumentBadge(
                        kind: MeetingDocumentKind.minutes,
                        isNew: hasNewDocuments,
                      ),
                    if (meeting.hasAnnouncement)
                      DocumentBadge(
                        kind: MeetingDocumentKind.announcement,
                        isNew: hasNewDocuments && !meeting.hasMinutes,
                      ),
                  ],
                ),
              ),
          ],
        ),
        trailing: meeting.hasDetails ? const Icon(Icons.chevron_right) : null,
      ),
    );
  }
}
