import 'package:equatable/equatable.dart';

class AgendaItem extends Equatable {
  const AgendaItem({required this.number, required this.title});

  final String number;
  final String title;

  int get depth => '.'.allMatches(number.trim()).length;

  @override
  List<Object?> get props => [number, title];
}
