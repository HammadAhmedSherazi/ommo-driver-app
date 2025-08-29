part of 'generics.dart';

String formattedDateDMY(DateTime dateTime) {
  String twoDigitString(int value) => value.toString().padLeft(2, '0');

  return '${twoDigitString(dateTime.day)}-${twoDigitString(dateTime.month)}-${dateTime.year}';
}

String getDaysLeft(DateTime date, {String? text}) {
  DateTime now = DateTime.now();
  int daysLeft = date.difference(now).inDays;

  if (daysLeft < 0) {
    return "";
  } else if (daysLeft == 0) {
    return "Today";
  } else {
    return "$daysLeft$text";
  }
}

String timeAgo(DateTime dateTime) {
  Duration difference = DateTime.now().difference(dateTime);

  if (difference.inSeconds < 60) {
    return '${difference.inSeconds} seconds ago';
  } else if (difference.inMinutes < 60) {
    return '${difference.inMinutes} minutes ago';
  } else if (difference.inHours < 24) {
    return '${difference.inHours} hours ago';
  } else if (difference.inDays < 7) {
    return '${difference.inDays} days ago';
  } else if (difference.inDays < 30) {
    return '${(difference.inDays / 7).floor()} weeks ago';
  } else if (difference.inDays < 365) {
    return '${(difference.inDays / 30).floor()} months ago';
  } else {
    return '${(difference.inDays / 365).floor()} years ago';
  }
}