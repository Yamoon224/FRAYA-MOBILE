library;

import 'package:flutter/material.dart';

/// Recadre la carte sur l'itinéraire complet après que le chauffeur a déplacé la carte.
class DriverRouteRecenterButton extends StatelessWidget {
  const DriverRouteRecenterButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      shape: const CircleBorder(),
      color: Colors.white,
      child: IconButton(
        tooltip: 'Recentrer l\'itinéraire',
        onPressed: onPressed,
        icon: const Icon(Icons.alt_route, color: Color(0xFF0B57D0)),
      ),
    );
  }
}
