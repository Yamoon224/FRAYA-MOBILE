import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../providers/booking_provider.dart';
import '../../../../shared/providers/places_provider.dart';
import '../providers/ride_summary_controller.dart';
import '../../history/providers/history_provider.dart';
import '../widgets/ride_summary/summary_card.dart';
import '../widgets/ride_summary/ride_details_section.dart';
import '../widgets/ride_summary/rating_section.dart';
import '../widgets/ride_summary/ride_summary_actions.dart';
import '../widgets/ride_summary/report_problem_sheet.dart';

/// Écran de résumé post-course.
///
/// Affiche le récapitulatif de la course terminée et permet
/// au passager de noter le chauffeur et laisser un pourboire.
class RideSummaryScreen extends ConsumerWidget {
  const RideSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ride =
        ref.watch(completedRideControllerProvider) ??
        ref.watch(activeRideControllerProvider);
    final summaryState = ref.watch(rideSummaryControllerProvider);
    final pickup = ref.watch(selectedPickupProvider);
    final destination = ref.watch(selectedDestinationProvider);
    if (ride == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 56,
                  color: context.colors.textSecondary,
                ),
                const SizedBox(height: AppTheme.spacingLg),
                Text(
                  'Course terminée',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Retrouvez votre course dans l\'historique pour noter le chauffeur.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(color: context.colors.textSecondary),
                ),
                const SizedBox(height: AppTheme.spacingXl),
                FilledButton(
                  onPressed: () {
                    ref.read(bookingFlowProvider.notifier).reset();
                    context.go(RoutePaths.history);
                  },
                  child: const Text('Ouvrir l\'historique'),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(bookingFlowProvider.notifier).reset();
                    context.go(RoutePaths.passengerHome);
                  },
                  child: const Text('Retour à l\'accueil'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Column(
            children: [
              const SizedBox(height: AppTheme.spacingXl),
              const _SuccessHeader(),
              const SizedBox(height: AppTheme.spacing2xl),
              SummaryCard(
                child: RideDetailsSection(
                  ride: ride,
                  pickupName: pickup?.name,
                  destinationName: destination?.name,
                ),
              ),
              const SizedBox(height: AppTheme.spacingLg),
              SummaryCard(
                child: RatingSection(
                  driverName: ride.driverName,
                  driverRating: ride.driverRating,
                  currentRating: summaryState.rating,
                  currentComment: summaryState.comment,
                  onRatingChanged: (rating) => ref
                      .read(rideSummaryControllerProvider.notifier)
                      .updateRating(rating),
                  onCommentChanged: (comment) => ref
                      .read(rideSummaryControllerProvider.notifier)
                      .updateComment(comment),
                ),
              ),
              const SizedBox(height: AppTheme.spacingLg),
              // SummaryCard(
              //   // child: TipSection(
              //   //   selectedTip: summaryState.selectedTip,
              //   //   onTipSelected: (tip) => ref
              //   //       .read(rideSummaryControllerProvider.notifier)
              //   //       .updateTip(tip),
              //   // ),
              // ),
              const SizedBox(height: AppTheme.spacingLg),
              _buildReportButton(context, ride.rideId),
              const SizedBox(height: AppTheme.spacing2xl),
              RideSummaryActions(
                rideId: ride.rideId,
                onFinish: () => _finish(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportButton(BuildContext context, String rideId) {
    return TextButton.icon(
      onPressed: () => ReportProblemSheet.show(context, rideId),
      icon: Icon(
        Icons.flag_outlined,
        color: context.colors.textSecondary,
        size: 18,
      ),
      label: Text(
        'Signaler un problème',
        style: AppTextStyles.small.copyWith(color: context.colors.textSecondary),
      ),
    );
  }

  void _finish(BuildContext context, WidgetRef ref) {
    ref.invalidate(rideHistoryProvider);
    ref.read(bookingFlowProvider.notifier).reset();
    context.go(RoutePaths.passengerHome);
  }
}

/// En-tête de succès avec icône et texte.
class _SuccessHeader extends StatelessWidget {
  const _SuccessHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 48),
          ),
        ),
        const SizedBox(height: AppTheme.spacingLg),
        Text(
          'Course terminée !',
          style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Vous êtes bien arrivé à destination',
          style: AppTextStyles.body.copyWith(color: context.colors.textSecondary),
        ),
      ],
    );
  }
}
