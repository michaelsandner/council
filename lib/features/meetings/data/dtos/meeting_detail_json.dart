import '../../domain/entities/agenda_item.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/entities/attendance.dart';
import '../../domain/entities/meeting_detail.dart';
import '../../domain/entities/minutes.dart';
import '../../domain/entities/vote_result.dart';
import 'meeting_json.dart';

Map<String, dynamic> agendaItemToJson(AgendaItem item) => {
  'number': item.number,
  'title': item.title,
};

AgendaItem agendaItemFromJson(Map<String, dynamic> json) =>
    AgendaItem(number: json['number'] as String, title: json['title'] as String);

Map<String, dynamic> voteToJson(VoteResult vote) => {
  'summary': vote.summary,
  if (vote.inFavour != null) 'inFavour': vote.inFavour,
  if (vote.against != null) 'against': vote.against,
  if (vote.present != null) 'present': vote.present,
};

VoteResult voteFromJson(Map<String, dynamic> json) => VoteResult(
  summary: json['summary'] as String,
  inFavour: json['inFavour'] as int?,
  against: json['against'] as int?,
  present: json['present'] as int?,
);

Map<String, dynamic> attendeeToJson(Attendee attendee) => {
  'name': attendee.name,
  if (attendee.note != null) 'note': attendee.note,
};

Attendee attendeeFromJson(Map<String, dynamic> json) =>
    Attendee(name: json['name'] as String, note: json['note'] as String?);

Map<String, dynamic> attendanceGroupToJson(AttendanceGroup group) => {
  'role': group.role,
  'members': group.members.map(attendeeToJson).toList(),
};

AttendanceGroup attendanceGroupFromJson(Map<String, dynamic> json) =>
    AttendanceGroup(
      role: json['role'] as String,
      members: (json['members'] as List<dynamic>)
          .map((member) => attendeeFromJson(member as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> announcementToJson(Announcement announcement) => {
  'heading': announcement.heading,
  if (announcement.sessionNumber != null)
    'sessionNumber': announcement.sessionNumber,
  if (announcement.date != null) 'date': encodeDate(announcement.date!),
  if (announcement.startTime != null) 'startTime': announcement.startTime,
  if (announcement.location != null) 'location': announcement.location,
  'agenda': announcement.agenda.map(agendaItemToJson).toList(),
  if (announcement.notes.isNotEmpty) 'notes': announcement.notes,
  if (announcement.closingNote != null) 'closingNote': announcement.closingNote,
  if (announcement.issuedOn != null) 'issuedOn': announcement.issuedOn,
  if (announcement.signedBy != null) 'signedBy': announcement.signedBy,
};

Announcement announcementFromJson(Map<String, dynamic> json) => Announcement(
  heading: json['heading'] as String,
  sessionNumber: json['sessionNumber'] as int?,
  date: json['date'] == null ? null : decodeDate(json['date'] as String),
  startTime: json['startTime'] as String?,
  location: json['location'] as String?,
  agenda: (json['agenda'] as List<dynamic>? ?? const [])
      .map((item) => agendaItemFromJson(item as Map<String, dynamic>))
      .toList(),
  notes: (json['notes'] as List<dynamic>? ?? const [])
      .map((note) => note as String)
      .toList(),
  closingNote: json['closingNote'] as String?,
  issuedOn: json['issuedOn'] as String?,
  signedBy: json['signedBy'] as String?,
);

Map<String, dynamic> minutesItemToJson(MinutesItem item) => {
  'number': item.number,
  'title': item.title,
  if (item.facts != null) 'facts': item.facts,
  if (item.decision != null) 'decision': item.decision,
  if (item.vote != null) 'vote': voteToJson(item.vote!),
};

MinutesItem minutesItemFromJson(Map<String, dynamic> json) => MinutesItem(
  number: json['number'] as String,
  title: json['title'] as String,
  facts: json['facts'] as String?,
  decision: json['decision'] as String?,
  vote: json['vote'] == null
      ? null
      : voteFromJson(json['vote'] as Map<String, dynamic>),
);

Map<String, dynamic> minutesToJson(Minutes minutes) => {
  'heading': minutes.heading,
  if (minutes.sessionNumber != null) 'sessionNumber': minutes.sessionNumber,
  if (minutes.date != null) 'date': encodeDate(minutes.date!),
  if (minutes.startTime != null) 'startTime': minutes.startTime,
  if (minutes.endTime != null) 'endTime': minutes.endTime,
  if (minutes.location != null) 'location': minutes.location,
  if (minutes.present.isNotEmpty)
    'present': minutes.present.map(attendanceGroupToJson).toList(),
  if (minutes.absent.isNotEmpty)
    'absent': minutes.absent.map(attendanceGroupToJson).toList(),
  'items': minutes.items.map(minutesItemToJson).toList(),
};

Minutes minutesFromJson(Map<String, dynamic> json) => Minutes(
  heading: json['heading'] as String,
  sessionNumber: json['sessionNumber'] as int?,
  date: json['date'] == null ? null : decodeDate(json['date'] as String),
  startTime: json['startTime'] as String?,
  endTime: json['endTime'] as String?,
  location: json['location'] as String?,
  present: (json['present'] as List<dynamic>? ?? const [])
      .map((group) => attendanceGroupFromJson(group as Map<String, dynamic>))
      .toList(),
  absent: (json['absent'] as List<dynamic>? ?? const [])
      .map((group) => attendanceGroupFromJson(group as Map<String, dynamic>))
      .toList(),
  items: (json['items'] as List<dynamic>? ?? const [])
      .map((item) => minutesItemFromJson(item as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> meetingDetailToJson(MeetingDetail detail) => {
  'meetingId': detail.meetingId,
  if (detail.announcement != null)
    'announcement': announcementToJson(detail.announcement!),
  if (detail.minutes != null) 'minutes': minutesToJson(detail.minutes!),
};

MeetingDetail meetingDetailFromJson(Map<String, dynamic> json) => MeetingDetail(
  meetingId: json['meetingId'] as String,
  announcement: json['announcement'] == null
      ? null
      : announcementFromJson(json['announcement'] as Map<String, dynamic>),
  minutes: json['minutes'] == null
      ? null
      : minutesFromJson(json['minutes'] as Map<String, dynamic>),
);
