/// Small date and name helpers used by the components.
///
/// These are intentionally dependency-free rather than using `intl`. Words
/// that appear in the output are passed in by the caller, which reads them
/// from [StreamChatTranslations], so that this file holds only the date
/// arithmetic and not any English.
library;

const List<String> _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const List<String> _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String _two(int value) => value.toString().padLeft(2, '0');

/// `14:05`, in the local timezone.
String formatTimeOfDay(DateTime date) {
  final local = date.toLocal();
  return '${_two(local.hour)}:${_two(local.minute)}';
}

/// Whole-day distance between [date] and today, ignoring the time of day.
int _daysAgo(DateTime date) {
  final local = date.toLocal();
  final today = DateTime.now();
  final thatDay = DateTime(local.year, local.month, local.day);
  final thisDay = DateTime(today.year, today.month, today.day);
  return thisDay.difference(thatDay).inDays;
}

/// Compact timestamp for channel list tiles.
///
/// Today renders as a time, the last week as a weekday, anything older as a
/// numeric date.
String formatChannelTimestamp(DateTime date, {String yesterday = 'Yesterday'}) {
  final days = _daysAgo(date);
  if (days <= 0) return formatTimeOfDay(date);
  if (days == 1) return yesterday;
  if (days < 7) return _weekdays[date.toLocal().weekday - 1];
  final local = date.toLocal();
  return '${_two(local.day)}/${_two(local.month)}/${local.year}';
}

/// Heading for the date separators in the message list.
String formatDateDivider(
  DateTime date, {
  String today = 'Today',
  String yesterday = 'Yesterday',
}) {
  final days = _daysAgo(date);
  if (days <= 0) return today;
  if (days == 1) return yesterday;
  final local = date.toLocal();
  final month = _months[local.month - 1];
  if (local.year == DateTime.now().year) return '$month ${local.day}';
  return '$month ${local.day}, ${local.year}';
}

/// Whether two timestamps fall on the same calendar day.
bool isSameDay(DateTime a, DateTime b) {
  final localA = a.toLocal();
  final localB = b.toLocal();
  return localA.year == localB.year &&
      localA.month == localB.month &&
      localA.day == localB.day;
}

/// Up to two uppercase initials for [name], used as an avatar fallback.
String initialsFor(String? name) {
  final trimmed = name?.trim() ?? '';
  if (trimmed.isEmpty) return '?';
  final words = trimmed.split(RegExp(r'\s+')).where((it) => it.isNotEmpty);
  if (words.isEmpty) return '?';
  if (words.length == 1) {
    final word = words.first;
    return word.characters(2).toUpperCase();
  }
  return (words.first.characters(1) + words.last.characters(1)).toUpperCase();
}

extension on String {
  /// The first [count] characters, or the whole string if it is shorter.
  String characters(int count) => length <= count ? this : substring(0, count);
}

/// A stable hue in `[0, 360)` derived from [seed].
///
/// Gives every user a consistent avatar colour without needing a palette
/// lookup or storing anything.
int hueFor(String seed) {
  var hash = 0;
  for (final unit in seed.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return hash % 360;
}
