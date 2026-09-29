import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fraya_mobile/core/theme/app_colors.dart';
import 'package:fraya_mobile/core/theme/app_text_styles.dart';
import 'package:fraya_mobile/core/theme/app_theme.dart';
import 'package:fraya_mobile/core/utils/extensions.dart';
import '../providers/ride_details_provider.dart';
import '../providers/ride_details_controller.dart';
import '../widgets/ride_details_header.dart';
import '../widgets/ride_details_map.dart';
import '../widgets/ride_summary_card.dart';
import '../widgets/ride_itinerary_timeline.dart';
import '../widgets/driver_info_card.dart';
import '../widgets/payment_info_card.dart';
import '../widgets/ride_action_buttons.dart';
import 'package:fraya_mobile/shared/widgets/fraya_skeleton.dart';

class RideDetailsScreen extends ConsumerWidget {
  final String rideId;
  const RideDetailsScreen({super.key, required this.rideId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rideAsync = ref.watch(rideDetailsProvider(rideId));
    final appBarColor = context.colors.surface;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: rideAsync.when(
        data: (ride) => RideDetailsHeader(ride: ride),
        loading: () => AppBar(elevation: 0, backgroundColor: appBarColor),
        error: (error, stack) =>
            AppBar(elevation: 0, backgroundColor: appBarColor),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(rideDetailsProvider(rideId));
          await ref.read(rideDetailsProvider(rideId).future);
        },
        child: rideAsync.when(
          data: (ride) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // Carte Interactive
                RideDetailsMap(ride: ride),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMd,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: AppTheme.spacingMd),

                      // Bouton "Refaire ce trajet"
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusXl,
                          ),
                          boxShadow: AppColors.shadowMd,
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () => ref
                              .read(rideDetailsControllerProvider.notifier)
                              .reorderRide(context, ride),
                          icon: const Icon(Icons.refresh, size: 24),
                          label: const Text('Refaire ce trajet'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: context.colors.textPrimary,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            textStyle: AppTextStyles.button.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Résumé (Date, Heure, Durée, Distance)
                      RideSummaryCard(ride: ride),

                      const SizedBox(height: 12),

                      // Itinéraire
                      RideItineraryTimeline(ride: ride),

                      const SizedBox(height: 12),

                      // Infos Chauffeur & Véhicule
                      DriverInfoCard(ride: ride),

                      const SizedBox(height: 12),

                      // Paiement
                      PaymentInfoCard(ride: ride),

                      // Boutons Reçu / Partager
                      RideActionButtons(ride: ride),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          loading: () => const RideDetailsSkeleton(),
          error: (e, _) => CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverFillRemaining(child: Center(child: Text('Erreur: $e'))),
            ],
          ),
        ),
      ),
    );
  }
}

class RideDetailsSkeleton extends StatelessWidget {
  const RideDetailsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Skeleton Map
          const FrayaSkeleton(
            height: 200,
            width: double.infinity,
            borderRadius: 0,
          ),

          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Column(
              children: [
                const FrayaSkeleton(
                  height: 54,
                  width: double.infinity,
                  borderRadius: 100,
                ),
                const SizedBox(height: 16),
                const FrayaSkeleton(
                  height: 120,
                  width: double.infinity,
                  borderRadius: 16,
                ),
                const SizedBox(height: 12),
                const FrayaSkeleton(
                  height: 150,
                  width: double.infinity,
                  borderRadius: 16,
                ),
                const SizedBox(height: 12),
                const FrayaSkeleton(
                  height: 100,
                  width: double.infinity,
                  borderRadius: 16,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
