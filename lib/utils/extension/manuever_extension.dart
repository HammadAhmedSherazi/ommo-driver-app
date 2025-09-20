import 'package:flutter/material.dart';
import 'package:here_sdk/routing.dart';

extension ManeuverExtension on Maneuver {
  String get formattedDistance {
    final miles = (lengthInMeters / 1609).toStringAsFixed(1); // in miles
    return "$miles mi";
  }

  String get formattedDuration {
    final minutes = duration.inMinutes;
    final hours = duration.inHours;

    if (hours > 0) {
      final mins = minutes % 60;
      return "${hours}h ${mins}m";
    }
    return "${minutes}m";
  }

  IconData get toIcon {
    switch (action) {
      // Start / End
      case ManeuverAction.depart:
        return Icons.trip_origin; // Start
      case ManeuverAction.arrive:
        return Icons.flag; // Destination

      // U-turns
      case ManeuverAction.leftUTurn:
      case ManeuverAction.rightUTurn:
        return Icons.u_turn_left; // No right version in Material

      // Left turns
      case ManeuverAction.sharpLeftTurn:
        return Icons.turn_sharp_left;
      case ManeuverAction.leftTurn:
        return Icons.turn_left;
      case ManeuverAction.slightLeftTurn:
        return Icons.turn_slight_left;

      // Right turns
      case ManeuverAction.sharpRightTurn:
        return Icons.turn_sharp_right;
      case ManeuverAction.rightTurn:
        return Icons.turn_right;
      case ManeuverAction.slightRightTurn:
        return Icons.turn_slight_right;

      // Continue straight
      case ManeuverAction.continueOn:
        return Icons.straight;

      // Highway exits & ramps
      case ManeuverAction.leftExit:
      case ManeuverAction.leftRamp:
        return Icons.call_split; // exit/merge left
      case ManeuverAction.rightExit:
      case ManeuverAction.rightRamp:
        return Icons.call_split; // exit/merge right
      case ManeuverAction.leftFork:
        return Icons.turn_left;
      case ManeuverAction.middleFork:
        return Icons.straight;
      case ManeuverAction.rightFork:
        return Icons.turn_right;

      // Enter highways
      case ManeuverAction.enterHighwayFromLeft:
        return Icons.merge; // Custom merge icon
      case ManeuverAction.enterHighwayFromRight:
        return Icons.merge;

      // Roundabouts (left / right, exits 1–12)
      case ManeuverAction.leftRoundaboutEnter:
      case ManeuverAction.rightRoundaboutEnter:
      case ManeuverAction.leftRoundaboutPass:
      case ManeuverAction.rightRoundaboutPass:
      case ManeuverAction.leftRoundaboutExit1:
      case ManeuverAction.leftRoundaboutExit2:
      case ManeuverAction.leftRoundaboutExit3:
      case ManeuverAction.leftRoundaboutExit4:
      case ManeuverAction.leftRoundaboutExit5:
      case ManeuverAction.leftRoundaboutExit6:
      case ManeuverAction.leftRoundaboutExit7:
      case ManeuverAction.leftRoundaboutExit8:
      case ManeuverAction.leftRoundaboutExit9:
      case ManeuverAction.leftRoundaboutExit10:
      case ManeuverAction.leftRoundaboutExit11:
      case ManeuverAction.leftRoundaboutExit12:
      case ManeuverAction.rightRoundaboutExit1:
      case ManeuverAction.rightRoundaboutExit2:
      case ManeuverAction.rightRoundaboutExit3:
      case ManeuverAction.rightRoundaboutExit4:
      case ManeuverAction.rightRoundaboutExit5:
      case ManeuverAction.rightRoundaboutExit6:
      case ManeuverAction.rightRoundaboutExit7:
      case ManeuverAction.rightRoundaboutExit8:
      case ManeuverAction.rightRoundaboutExit9:
      case ManeuverAction.rightRoundaboutExit10:
      case ManeuverAction.rightRoundaboutExit11:
      case ManeuverAction.rightRoundaboutExit12:
        return Icons.roundabout_right; // Material 3 has roundabout icons

      default:
        return Icons.help_outline; // fallback
    }
  }
}
