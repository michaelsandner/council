import 'package:equatable/equatable.dart';

class Attendee extends Equatable {
  const Attendee({required this.name, this.note});

  final String name;
  final String? note;

  @override
  List<Object?> get props => [name, note];
}

class AttendanceGroup extends Equatable {
  const AttendanceGroup({required this.role, required this.members});

  final String role;
  final List<Attendee> members;

  @override
  List<Object?> get props => [role, members];
}
