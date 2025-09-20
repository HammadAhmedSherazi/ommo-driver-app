import 'package:here_sdk/routing.dart';

extension RouteExtension on Route {
  bool get hasTolls {
    for (final section in sections) {
      final tolls = section.tolls;
      if (tolls.isNotEmpty) {
        return true;
      }
    }
    return false;
  }

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

  String get getRouteName {
    for (final section in sections) {
      for (final maneuver in section.maneuvers) {
        final roadName = maneuver.nextRoadTexts.names.items.first.text;
        if (roadName.isNotEmpty) {
          return "Via $roadName";
        }
      }
    }
    return "Unnamed Route";
  }
}
