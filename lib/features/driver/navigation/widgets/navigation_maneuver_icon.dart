library;

import 'package:flutter/material.dart';

/// Icône d'une manoeuvre Google Directions (`maneuver` d'une step).
IconData navigationManeuverIcon(String maneuver) {
  switch (maneuver) {
    case 'turn-left':
    case 'fork-left':
    case 'ramp-left':
      return Icons.turn_left_rounded;
    case 'turn-right':
    case 'fork-right':
    case 'ramp-right':
      return Icons.turn_right_rounded;
    case 'turn-slight-left':
    case 'keep-left':
      return Icons.turn_slight_left_rounded;
    case 'turn-slight-right':
    case 'keep-right':
      return Icons.turn_slight_right_rounded;
    case 'turn-sharp-left':
      return Icons.turn_sharp_left_rounded;
    case 'turn-sharp-right':
      return Icons.turn_sharp_right_rounded;
    case 'uturn-left':
    case 'uturn-right':
      return Icons.u_turn_left_rounded;
    case 'roundabout-left':
      return Icons.roundabout_left_rounded;
    case 'roundabout-right':
      return Icons.roundabout_right_rounded;
    case 'merge':
      return Icons.merge_rounded;
    case 'straight':
    default:
      return Icons.straight_rounded;
  }
}
