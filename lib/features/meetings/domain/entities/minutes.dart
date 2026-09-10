import 'package:equatable/equatable.dart';

import 'attendance.dart';
import 'vote_result.dart';

class MinutesItem extends Equatable {
  const MinutesItem({
    required this.number,
    required this.title,
    this.facts,
    this.decision,
    this.vote,
  });

  final String number;
  final String title;
  final String? facts;
  final String? decision;
  final VoteResult? vote;

  int get depth => '.'.allMatches(number.trim()).length;

  @override
  List<Object?> get props => [number, title, facts, decision, vote];
}

class Minutes extends Equatable {
  const Minutes({
    required this.heading,
    required this.items,
    this.sessionNumber,
    this.date,
    this.startTime,
    this.endTime,
    this.location,
    this.present = const [],
    this.absent = const [],
  });

  final String heading;
  final List<MinutesItem> items;
  final int? sessionNumber;
  final DateTime? date;
  final String? startTime;
  final String? endTime;
  final String? location;
  final List<AttendanceGroup> present;
  final List<AttendanceGroup> absent;

  @override
  List<Object?> get props => [
    heading,
    items,
    sessionNumber,
    date,
    startTime,
    endTime,
    location,
    present,
    absent,
  ];
}
