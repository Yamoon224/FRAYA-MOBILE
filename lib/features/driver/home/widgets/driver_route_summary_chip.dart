library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';

/// Distance lisible : « 450 m » sous le kilomètre, « 2,3 km » au-delà.
String formatRouteDistance(double kilometers) {
  if (kilometers < 1) return '${(kilometers * 1000).round()} m';
  return '${kilometers.toStringAsFixed(1).replaceAll('.', ',')} km';
}

/// Résumé de l'itinéraire affiché sur la carte : où l'on va, en combien de temps, sur quelle distance.
class DriverRouteSummaryChip extends StatelessWidget {
  const DriverRouteSummaryChip({
    super.key,
    required this.isHeadingToPickup,
    required this.minutes,
    required this.kilometers,
  });

  final bool isHeadingToPickup;
  final int minutes;
  final double kilometers;

  @override
  Widget build(BuildContext context) {
    final target = isHeadingToPickup ? 'Vers le client' : 'Vers la destination';
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(999),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isHeadingToPickup ? Icons.person_pin_circle : Icons.flag,
              size: 18,
              color: const Color(0xFF0B57D0),
            ),
            const SizedBox(width: 8),
            Text(
              '$target · $minutes min · ${formatRouteDistance(kilometers)}',
              style: AppTextStyles.small.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
