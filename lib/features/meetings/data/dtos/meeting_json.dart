import '../../domain/entities/meeting.dart';
import '../../domain/entities/meeting_document.dart';

String encodeDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

DateTime decodeDate(String value) => DateTime.parse(value);

Map<String, dynamic> meetingDocumentToJson(MeetingDocument document) => {
  'id': document.id,
  'kind': document.kind.name,
  'label': document.label,
  'sourceUrl': document.sourceUrl,
};

MeetingDocument meetingDocumentFromJson(Map<String, dynamic> json) =>
    MeetingDocument(
      id: json['id'] as String,
      kind: MeetingDocumentKind.values.byName(json['kind'] as String),
      label: json['label'] as String,
      sourceUrl: json['sourceUrl'] as String,
    );

Map<String, dynamic> meetingToJson(Meeting meeting) => {
  'id': meeting.id,
  'title': meeting.title,
  'date': encodeDate(meeting.date),
  if (meeting.startTime != null) 'startTime': meeting.startTime,
  if (meeting.endTime != null) 'endTime': meeting.endTime,
  if (meeting.location != null) 'location': meeting.location,
  if (meeting.announcement != null)
    'announcement': meetingDocumentToJson(meeting.announcement!),
  if (meeting.minutes != null)
    'minutes': meetingDocumentToJson(meeting.minutes!),
};

Meeting meetingFromJson(Map<String, dynamic> json) => Meeting(
  id: json['id'] as String,
  title: json['title'] as String,
  date: decodeDate(json['date'] as String),
  startTime: json['startTime'] as String?,
  endTime: json['endTime'] as String?,
  location: json['location'] as String?,
  announcement: json['announcement'] == null
      ? null
      : meetingDocumentFromJson(json['announcement'] as Map<String, dynamic>),
  minutes: json['minutes'] == null
      ? null
      : meetingDocumentFromJson(json['minutes'] as Map<String, dynamic>),
);
