import 'package:intl/intl.dart';

class DateFormatter {
  static final _dateFormat = DateFormat('MMM d, yyyy');
  static final _timeFormat = DateFormat('h:mm a');
  static final _dateTimeFormat = DateFormat('MMM d, yyyy \u2022 h:mm a');

  static String formatDate(DateTime dt) => _dateFormat.format(dt);
  static String formatTime(DateTime dt) => _timeFormat.format(dt);
  static String formatDateTime(DateTime dt) => _dateTimeFormat.format(dt);

  static String formatRelative(DateTime dt) {
    final now = DateTime.now();
    final diff = dt.difference(now);
    if (diff.isNegative) {
      final abs = now.difference(dt);
      if (abs.inDays > 0) return '${abs.inDays}d ago';
      if (abs.inHours > 0) return '${abs.inHours}h ago';
      return '${abs.inMinutes}m ago';
    } else {
      if (diff.inDays > 0) return 'in ${diff.inDays}d';
      if (diff.inHours > 0) return 'in ${diff.inHours}h';
      return 'in ${diff.inMinutes}m';
    }
  }

  static String formatCountdown(DateTime resetTime) {
    final now = DateTime.now();
    if (now.isAfter(resetTime)) return 'Expired';
    final diff = resetTime.difference(now);
    if (diff.inDays >= 1) {
      return 'Resets in ${diff.inDays}d ${diff.inHours.remainder(24)}h';
    } else if (diff.inHours >= 1) {
      return 'Resets in ${diff.inHours}h ${diff.inMinutes.remainder(60)}m';
    } else {
      return 'Resets in ${diff.inMinutes}m';
    }
  }
}
