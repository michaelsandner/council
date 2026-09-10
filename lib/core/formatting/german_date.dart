import 'package:intl/intl.dart';

final _weekdayAndDate = DateFormat('EEEE, d. MMMM y', 'de_DE');
final _shortDate = DateFormat('d. MMM y', 'de_DE');
final _monthAndYear = DateFormat('MMMM y', 'de_DE');

String formatFullDate(DateTime date) => _weekdayAndDate.format(date);

String formatShortDate(DateTime date) => _shortDate.format(date);

String formatMonth(DateTime date) => _monthAndYear.format(date);

String formatTimeRange(String? start, String? end) {
  if (start == null) return '';
  return end == null ? '$start Uhr' : '$start – $end Uhr';
}
