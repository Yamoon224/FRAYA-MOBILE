library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../domain/models/driver_ride.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/fraya_button.dart';
import '../models/driver_ride_completion_pricing.dart';
import '../providers/driver_ride_completion_controller.dart';
import '../widgets/driver_passenger_rating_card.dart';
import '../widgets/driver_ride_completion_payment_section.dart';
import '../widgets/driver_ride_completion_summary_card.dart';

class DriverRideCompletionScreen extends ConsumerWidget {
  const DriverRideCompletionScreen({super.key, required this.ride});

  final DriverRide ride;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completionState = ref.watch(driverRideCompletionControllerProvider);
    final controller = ref.read(
      driverRideCompletionControllerProvider.notifier,
    );
    final isLocked =
        completionState.isSubmitting || completionState.isCompleted;
    final pricing = DriverRideCompletionPricing.fromRide(ride);

    ref.listen(driverRideCompletionControllerProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        AppSnackBar.showError(context, next.errorMessage!);
      }
      if (next.isCompleted && previous?.isCompleted != true) {
        AppSnackBar.showSuccess(context, 'Course terminée avec succès.');
      }
    });

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.background,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          completionState.isCompleted
              ? 'Course terminée'
              : 'Terminer la course',
          style: AppTextStyles.h1.copyWith(fontSize: 20),
        ),
        leading: _CircleIconButton(
          icon: Icons.arrow_back_rounded,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: context.responsiveBody(
          ListView(
            padding: EdgeInsets.fromLTRB(
              context.horizontalPagePadding,
              12,
              context.horizontalPagePadding,
              24,
            ),
            children: [
              _CompletionHeader(
                amount: pricing.finalPrice.toCFA,
                isCompleted: completionState.isCompleted,
              ),
              const SizedBox(height: AppTheme.spacingLg),
              DriverRideCompletionSummaryCard(ride: ride),
              const SizedBox(height: AppTheme.spacingLg),
              DriverRideCompletionPaymentSection(
                selectedMethod: completionState.paymentMethod,
                onSelected: controller.updatePaymentMethod,
                enabled: !isLocked,
              ),
              const SizedBox(height: AppTheme.spacingLg),
              Text(
                'Evaluer le passager',
                style: context.textH2.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              DriverPassengerRatingCard(
                passengerName: ride.passengerName,
                rating: completionState.rating,
                comment: completionState.comment,
                onRatingChanged: controller.updateRating,
                onCommentChanged: controller.updateComment,
                enabled: !isLocked,
              ),
              const SizedBox(height: AppTheme.spacing2xl),
              FrayaButton(
                label: completionState.isCompleted
                    ? 'Retour au tableau de bord'
                    : 'Terminer et recevoir ${pricing.finalPrice.toCFA}',
                isLoading: completionState.isSubmitting,
                leftIcon: completionState.isCompleted
                    ? Icons.home_rounded
                    : Icons.attach_money_rounded,
                onPressed: () => _handlePrimaryAction(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handlePrimaryAction(BuildContext context, WidgetRef ref) async {
    final completionState = ref.read(driverRideCompletionControllerProvider);
    if (completionState.isCompleted) {
      context.goNamed(RouteNames.driverHome);
      return;
    }
    await ref
        .read(driverRideCompletionControllerProvider.notifier)
        .submit(ride);
  }
}

class _CompletionHeader extends StatelessWidget {
  const _CompletionHeader({required this.amount, required this.isCompleted});

  final String amount;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final heroSize = context.responsiveValue<double>(
      compact: 72,
      phone: 88,
      largePhone: 88,
      tablet: 108,
    );
    return Column(
      children: [
        Container(
          width: heroSize,
          height: heroSize,
          decoration: BoxDecoration(
            gradient: isCompleted
                ? AppColors.goldGradient
                : AppColors.primaryGradient,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCompleted ? Icons.check_rounded : Icons.payments_outlined,
            size: heroSize * 0.5,
            color: context.colors.textPrimary,
          ),
        ),
        const SizedBox(height: AppTheme.spacingLg),
        Text(
          isCompleted ? 'Course terminée !' : 'Clôturer la course',
          style: AppTextStyles.h1.copyWith(
            fontSize: context.responsiveValue<double>(
              compact: 22,
              phone: 28,
              largePhone: 28,
              tablet: 34,
            ),
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Text(
          isCompleted
              ? 'Excellent travail'
              : 'Confirmez le paiement et finalisez cette course.',
          style: AppTextStyles.body.copyWith(color: context.colors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Text(
          amount,
          style: AppTextStyles.h2.copyWith(
            fontSize: 18,
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface,
        shape: BoxShape.circle,
        boxShadow: AppColors.shadowMd,
      ),
      child: IconButton(
        icon: Icon(icon, color: context.colors.textPrimary),
        onPressed: onPressed,
      ),
    );
  }
}
