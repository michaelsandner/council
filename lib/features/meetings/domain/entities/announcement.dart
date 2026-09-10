import 'package:equatable/equatable.dart';

import 'agenda_item.dart';

class Announcement extends Equatable {
  const Announcement({
    required this.heading,
    required this.agenda,
    this.sessionNumber,
    this.date,
    this.startTime,
    this.location,
    this.notes = const [],
    this.closingNote,
    this.issuedOn,
    this.signedBy,
  });

  final String heading;
  final List<AgendaItem> agenda;
  final int? sessionNumber;
  final DateTime? date;
  final String? startTime;
  final String? location;
  final List<String> notes;
  final String? closingNote;
  final String? issuedOn;
  final String? signedBy;

  @override
  List<Object?> get props => [
    heading,
    agenda,
    sessionNumber,
    date,
    startTime,
    location,
    notes,
    closingNote,
    issuedOn,
    signedBy,
  ];
}
