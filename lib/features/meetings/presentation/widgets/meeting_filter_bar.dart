import 'package:flutter/material.dart';

import '../cubit/meeting_filter.dart';

class MeetingFilterBar extends StatelessWidget {
  const MeetingFilterBar({
    required this.selected,
    required this.onSelect,
    super.key,
  });

  final MeetingFilter selected;
  final ValueChanged<MeetingFilter> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          for (final filter in MeetingFilter.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(_labelOf(filter)),
                selected: filter == selected,
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
                onSelected: (_) => onSelect(filter),
              ),
            ),
        ],
      ),
    );
  }

  String _labelOf(MeetingFilter filter) => switch (filter) {
    MeetingFilter.all => 'Alle',
    MeetingFilter.minutes => 'Niederschrift',
    MeetingFilter.agenda => 'Tagesordnung',
  };
}
