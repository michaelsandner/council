import 'dart:convert';
import 'dart:io';

import 'package:council/features/meetings/data/dtos/meeting_detail_json.dart';
import 'package:council/features/meetings/data/dtos/meeting_json.dart';
import 'package:council/features/meetings/data/parsing/pdf_text.dart';
import 'package:council/features/meetings/domain/entities/announcement.dart';
import 'package:council/features/meetings/domain/entities/meeting.dart';
import 'package:council/features/meetings/domain/entities/minutes.dart';

/// The published JSON tree the PWA reads from its own origin.
class CouncilArchive {
  CouncilArchive(this.root);

  final Directory root;

  static const indexFileName = 'index.json';

  File get indexFile => File('${root.path}/$indexFileName');

  Directory get detailDirectory => Directory('${root.path}/meetings');

  File detailFile(String meetingId) =>
      File('${detailDirectory.path}/$meetingId.json');

  List<Meeting> readMeetings() {
    final json = _readIndex();
    if (json == null) return const [];
    return (json['meetings'] as List<dynamic>)
        .map((entry) => meetingFromJson(entry as Map<String, dynamic>))
        .toList();
  }

  /// Stored results are only reusable when they came out of the current
  /// parsers; otherwise a parser fix would never reach documents already seen.
  bool get isStale => (_readIndex()?['parserVersion'] as int?) != parserVersion;

  Map<String, dynamic>? _readIndex() {
    if (!indexFile.existsSync()) return null;
    return jsonDecode(indexFile.readAsStringSync()) as Map<String, dynamic>;
  }

  StoredDetail? readDetail(String meetingId) {
    final file = detailFile(meetingId);
    if (!file.existsSync()) return null;
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final sources = (json['sources'] as Map<String, dynamic>? ?? const {});
    return StoredDetail(
      announcement: json['announcement'] == null
          ? null
          : announcementFromJson(json['announcement'] as Map<String, dynamic>),
      minutes: json['minutes'] == null
          ? null
          : minutesFromJson(json['minutes'] as Map<String, dynamic>),
      announcementDocumentId: sources['announcement'] as String?,
      minutesDocumentId: sources['minutes'] as String?,
    );
  }

  void writeDetail(String meetingId, StoredDetail detail) {
    detailDirectory.createSync(recursive: true);
    final json = <String, dynamic>{
      'meetingId': meetingId,
      if (detail.announcement != null)
        'announcement': announcementToJson(detail.announcement!),
      if (detail.minutes != null) 'minutes': minutesToJson(detail.minutes!),
      'sources': {
        if (detail.announcementDocumentId != null)
          'announcement': detail.announcementDocumentId,
        if (detail.minutesDocumentId != null)
          'minutes': detail.minutesDocumentId,
      },
    };
    detailFile(meetingId).writeAsStringSync(_encode(json));
  }

  void writeIndex(List<Meeting> meetings, {required String source}) {
    root.createSync(recursive: true);
    indexFile.writeAsStringSync(
      _encode({
        'generatedAt': DateTime.now().toUtc().toIso8601String(),
        'source': source,
        'parserVersion': parserVersion,
        'meetings': meetings.map(meetingToJson).toList(),
      }),
    );
  }

  void removeDetailsExcept(Set<String> meetingIds) {
    if (!detailDirectory.existsSync()) return;
    for (final entry in detailDirectory.listSync()) {
      if (entry is! File || !entry.path.endsWith('.json')) continue;
      final id = entry.uri.pathSegments.last.replaceAll('.json', '');
      if (!meetingIds.contains(id)) entry.deleteSync();
    }
  }

  String _encode(Object value) =>
      '${const JsonEncoder.withIndent('  ').convert(value)}\n';
}

class StoredDetail {
  const StoredDetail({
    this.announcement,
    this.minutes,
    this.announcementDocumentId,
    this.minutesDocumentId,
  });

  final Announcement? announcement;
  final Minutes? minutes;
  final String? announcementDocumentId;
  final String? minutesDocumentId;

  bool get isEmpty => announcement == null && minutes == null;
}
