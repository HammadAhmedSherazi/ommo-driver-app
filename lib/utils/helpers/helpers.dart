import '../../utils/utils.dart';
import 'package:flutter/material.dart';

class Helpers {
  Helpers._();

  static String formatDate(DateTime? date) {
    if (date == null) {
      return "";
    }
    String day = date.day.toString().padLeft(2, '0');
    String month = date.month.toString().padLeft(2, '0');
    String year = date.year.toString();
    return '$day/$month/$year';
  }
   static String formatDate2(DateTime? date) {
  if (date == null) return "";

  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString().substring(2); // Get last 2 digits

  return '$day/$month/$year'; // e.g., 17/06/25
}
static String formatTime12Hour(DateTime dateTime) {
  final hour = dateTime.hour;
  final minute = dateTime.minute.toString().padLeft(2, '0');

  final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
  final period = hour < 12 ? 'AM' : 'PM';

  return '$hour12:$minute $period';
}
static String formatFullDate(DateTime date) {
  const weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday'
  ];

  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  final weekday = weekdays[date.weekday - 1];
  final month = months[date.month - 1];
  final day = date.day;
  final year = date.year;

  return '$weekday, $month $day, $year';
}

  static String formatDateLong(DateTime date) {
    const List<String> monthNames = [
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

    String month = monthNames[date.month - 1];
    String day = date.day.toString();
    String year = date.year.toString();

    return '$month $day, $year'; // Example: June 17, 2025
  }

  static openBottomSheet({
    required BuildContext context,
    required Widget child,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => child,
    );
  }

  static String getDateLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final inputDate = DateTime(date.year, date.month, date.day);

  if (isSameDay(inputDate, today)) return "Today";
  if (isSameDay(inputDate, yesterday)) return "Yesterday";

  return formatDateLong(date); // e.g., June 20, 2025
}

static bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

  static Color setTextColor(String text){
    switch (text.toLowerCase()) {
      case 'awaiting approval':
      return AppColorTheme().primary;
      case 'approved':
      return AppColorTheme().approvedTextColor;
      case 'declined':
      return AppColorTheme().cancelTextColor;
        
       
      default:
        return AppColorTheme().primary;
    }
  }
 static String getTimeAgo(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);

  if (difference.inSeconds < 60) {
    return "Just now";
  } else if (difference.inMinutes < 60) {
    return "${difference.inMinutes} m${difference.inMinutes == 1 ? '' : 's'} ago";
  } else if (difference.inHours < 24) {
    return "${difference.inHours} hr${difference.inHours == 1 ? '' : 's'} ago";
  } else if (difference.inDays == 1) {
    return "Yesterday";
  } else if (difference.inDays < 7) {
    return "${difference.inDays} d${difference.inDays == 1 ? '' : 's'} ago";
  } else {
    return "${date.day}/${date.month}/${date.year}";
  }
}
static String formatDateTime(DateTime date) {
  final weekday = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'][date.weekday % 7];
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final period = date.hour >= 12 ? 'PM' : 'AM';
  final minute = date.minute.toString().padLeft(2, '0');

  return '$weekday – $hour:$minute $period';
}
}
