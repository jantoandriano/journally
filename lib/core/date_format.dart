const _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// e.g. "12 Mar 2026".
String formatDate(DateTime date) =>
    '${date.day} ${_monthNames[date.month - 1]} ${date.year}';

/// e.g. "12 Mar, 18:40".
String formatDateTime(DateTime date) {
  final hh = date.hour.toString().padLeft(2, '0');
  final mm = date.minute.toString().padLeft(2, '0');
  return '${date.day} ${_monthNames[date.month - 1]}, $hh:$mm';
}
