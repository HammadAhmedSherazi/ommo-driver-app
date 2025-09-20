import 'package:flutter/material.dart';
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
    DateTime etaTime = DateTime.now().add(Duration(seconds: duration.inSeconds));
    String etaStr = TimeOfDay.fromDateTime(etaTime).format(context);

    return etaStr;
  }

  String formattedSummary(context) => "($distanceInMiles • ${formattedETA(context)})";

  String formattedManeuverInstructionWithRemainingDistance(index, distanceMeters) {
    return "${maneuverInstruction(index)} in ${distanceMeters.toStringAsFixed(0)} m";
  }

  String maneuverInstruction(int? index) {
    if (index == null) return '';
    List<String> texts = [];
    for (route.Section section in sections) {
      for (route.Maneuver m in section.maneuvers) {
        texts.add(m.text);
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
}
