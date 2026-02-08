import 'package:flutter/material.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/routing.dart' as route;
import 'package:ommo/utils/extension/manuever_extension.dart';

extension RouteExtension on route.Route {
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

  String get distanceInMilesINNumber {
    double miles = lengthInMeters / 1609.34; // 1 mile = 1609.34 m
    return miles.toStringAsFixed(1);
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
        if (maneuver.nextRoadTexts.names.items.isNotEmpty) {
          final roadName = maneuver.nextRoadTexts.names.items.first.text;
          if (roadName.isNotEmpty) {
            return "Via $roadName";
          }
        }
      }
    }
    return "Unnamed Route";
  }

  String formattedETA(context) {
    DateTime etaTime = DateTime.now().add(
      Duration(seconds: duration.inSeconds),
    );
    String etaStr = TimeOfDay.fromDateTime(etaTime).format(context);

    return etaStr;
  }

  String formattedSummary(context) =>
      "($distanceInMiles • ${formattedETA(context)})";

  String formattedManeuverInstructionWithRemainingDistance(
    index,
    distanceMeters,
  ) {
    return "${maneuverInstruction(index)} in ${distanceMeters.toStringAsFixed(0)} m";
  }

  String maneuverInstruction(int? index) {
    if (index == null) return '';
    List<String> texts = [];
    for (route.Section section in sections) {
      for (route.Maneuver m in section.maneuvers) {
        if (m.action == route.ManeuverAction.arrive) {
          texts.add(reformatManeuver(m.text));
        } else {
          texts.add(m.text);
        }
      }
    }
    return (index >= 0 && index < texts.length) ? texts[index] : "";
  }

  String maneuverNextAddress(int? index) {
    if (index == null) return '';
    List<String> texts = [];
    for (route.Section section in sections) {
      for (route.Maneuver m in section.maneuvers) {
        if (m.nextRoadTexts.names.items.isNotEmpty) {
          texts.add(m.nextRoadTexts.names.items.first.text);
        } else if (m.roadTexts.names.items.isNotEmpty) {
          // fallback to current road name
          texts.add(m.roadTexts.names.items.first.text);
        } else {
          texts.add(""); // fallback if nothing
        }
      }
    }
    return (index >= 0 && index < texts.length) ? texts[index] : "";
  }

  IconData? maneuverInstructionIcon(int? index) {
    if (index == null) return null;
    List<IconData> icons = [];
    for (route.Section section in sections) {
      for (route.Maneuver m in section.maneuvers) {
        icons.add(m.toIcon);
      }
    }

    return (index >= 0 && index < icons.length) ? icons[index] : null;
  }

  String reformatManeuver(String instruction) {
    final lower = instruction.toLowerCase();

    // Determine left or right
    String side;
    if (lower.contains('right')) {
      side = 'right';
    } else if (lower.contains('left')) {
      side = 'left';
    } else {
      side = 'straight'; // fallback
    }

    // Choose wording based on whether it's a waypoint or destination
    final type = instruction.contains("waypoint") ? 'waypoint' : 'destination';

    return "Your $type is on your $side.";
  }

  /// Get maneuver coordinates by index
  GeoCoordinates? getManeuverCoordinates(int? index) {
    if (index == null) return null;
    int currentIndex = 0;
    for (route.Section section in sections) {
      for (route.Maneuver m in section.maneuvers) {
        if (currentIndex == index) {
          return m.coordinates;
        }
        currentIndex++;
      }
    }
    return null;
  }

  /// Calculate adjusted distance to maneuver using current location
  /// This compensates for the ~50ft (15m) delay in HERE SDK's reported distance
  double getAdjustedDistanceToManeuver(
    int? maneuverIndex,
    double reportedDistanceInMeters,
    GeoCoordinates? currentLocation,
  ) {
    if (maneuverIndex == null || currentLocation == null) {
      // If we don't have current location, apply a fixed offset for small distances
      // Only adjust when close to the turn (within 500ft / 152m)
      if (reportedDistanceInMeters < 152) {
        // Apply ~15m (50ft) offset, but ensure it doesn't go negative
        return (reportedDistanceInMeters - 15).clamp(0, double.infinity);
      }
      return reportedDistanceInMeters;
    }

    // Get maneuver coordinates
    final maneuverCoords = getManeuverCoordinates(maneuverIndex);
    if (maneuverCoords == null) {
      // Fallback to offset adjustment
      if (reportedDistanceInMeters < 152) {
        return (reportedDistanceInMeters - 15).clamp(0, double.infinity);
      }
      return reportedDistanceInMeters;
    }

    // Calculate actual distance from current location to maneuver point
    final actualDistance = currentLocation.distanceTo(maneuverCoords);

    // Use the actual calculated distance, which should be more accurate
    return actualDistance;
  }
}
