const _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// e.g. "12 Mar 2026".
String formatDate(DateTime date) {
  final local = date.toLocal();
  return '${local.day} ${_monthNames[local.month - 1]} ${local.year}';
}

/// e.g. "12 Mar, 18:40".
String formatDateTime(DateTime date) {
  final local = date.toLocal();
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  return '${local.day} ${_monthNames[local.month - 1]}, $hh:$mm';
}
