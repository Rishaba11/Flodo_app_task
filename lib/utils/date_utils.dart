import 'package:intl/intl.dart';

class TaskDateUtils {
  static String formatFull(DateTime date) {
    return DateFormat('MMMM d, yyyy').format(date);
  }

  static String formatShort(DateTime date) {
    return DateFormat('MMM d').format(date);
  }

  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  static bool isOverdue(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return date.isBefore(today);
  }
}