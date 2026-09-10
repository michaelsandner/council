import 'package:flutter/material.dart';

import '../../domain/entities/meeting_document.dart';

class DocumentBadge extends StatelessWidget {
  const DocumentBadge({required this.kind, this.isNew = false, super.key});

  final MeetingDocumentKind kind;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isMinutes = kind == MeetingDocumentKind.minutes;
    final background = isMinutes
        ? scheme.primaryContainer
        : scheme.tertiaryContainer;
    final foreground = isMinutes
        ? scheme.onPrimaryContainer
        : scheme.onTertiaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMinutes ? Icons.article_outlined : Icons.campaign_outlined,
            size: 14,
            color: foreground,
          ),
          const SizedBox(width: 4),
          Text(
            isMinutes ? 'Niederschrift' : 'Bekanntmachung',
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: foreground, fontWeight: FontWeight.w600),
          ),
          if (isNew) ...[
            const SizedBox(width: 4),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: scheme.error,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
