import 'package:here_sdk/routing.dart';

extension SectionExtension on Section {
  String get distanceInMiles {
    double miles = lengthInMeters / 1609.34; // 1 mile = 1609.34 m
    return "${miles.toStringAsFixed(1)} mi";
  }

  String get formattedDuration {
    final duration = Duration(seconds: this.duration.inSeconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return "${hours}h ${minutes}m";
    } else {
      return "${minutes}m";
    }
  }
}
