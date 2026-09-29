import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/directions_models.dart';
import '../../../../core/models/places_models.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/measurement_formatter.dart';
import '../../../../shared/providers/location_provider.dart';
import '../../../../shared/providers/places_provider.dart';
import 'route_summary_card.dart';

class RouteSummarySection extends ConsumerWidget {
  const RouteSummarySection({
    super.key,
    required this.directionsAsync,
    required this.destination,
    required this.onEditPickup,
    required this.onEditDestination,
  });

  final AsyncValue<DirectionsResult?> directionsAsync;
  final PlaceDetails? destination;
  final VoidCallback onEditPickup;
  final VoidCallback onEditDestination;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final directions = directionsAsync.asData?.value;
    final selectedPickup = ref.watch(selectedPickupProvider);
    final formattedAddress = ref.watch(formattedAddressProvider);
    final activeRoute = (directions != null && directions.routes.isNotEmpty)
        ? directions.mainRoute
        : null;
    final originCandidates = <String?>[
      selectedPickup?.address,
      formattedAddress,
    ];
    final originName = originCandidates
        .map((value) => value?.trim() ?? '')
        .firstWhere(
          (value) => value.isNotEmpty && !_isTransientAddressLabel(value),
          orElse: () => 'Position actuelle',
        );

    return directionsAsync.when(
      data: (directions) {
        if (activeRoute == null) {
          return Text(
            "Impossible de calculer l'itinéraire. Rafraîchissez le trajet.",
            style: AppTextStyles.body.copyWith(color: AppColors.error),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RouteSummaryCard(
              originName: originName,
              destinationName: destination?.name ?? '',
              distanceText: MeasurementFormatter.normalizeDistance(
                activeRoute.distanceText,
                fallback: '${activeRoute.distanceKm.toStringAsFixed(1)} km',
              ),
              durationText: MeasurementFormatter.normalizeDuration(
                activeRoute.arrivalTime ?? activeRoute.durationText,
                fallback: MeasurementFormatter.formatDurationMinutes(
                  activeRoute.effectiveDurationMinutes,
                ),
              ),
              onOriginTap: onEditPickup,
              onDestinationTap: onEditDestination,
            ),
          ],
        );
      },
      loading: () => const RouteSummarySkeleton(),
      error: (_, _) => Text(
        "Erreur lors du calcul de l'itinéraire",
        style: AppTextStyles.body.copyWith(color: AppColors.error),
      ),
    );
  }
}

bool _isTransientAddressLabel(String value) {
  final normalized = value.trim().toLowerCase();
  return normalized == 'ma position' ||
      normalized == 'position actuelle' ||
      normalized == 'position inconnue' ||
      normalized == 'recherche...' ||
      normalized == 'erreur adresse';
}
