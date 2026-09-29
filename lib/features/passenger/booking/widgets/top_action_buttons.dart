import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fraya_mobile/domain/models/ride_status.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../providers/booking_provider.dart';

class TopActionButtons extends ConsumerWidget {
  const TopActionButtons({
    super.key,
    this.arrivalTime,
    required this.onBackPressed,
  });

  final String? arrivalTime;
  final VoidCallback onBackPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flowState = ref.watch(bookingFlowProvider);
    final ride = ref.watch(activeRideControllerProvider);
    final liveDistanceText = ref.watch(
      activeRideLiveMetricsControllerProvider.select(
        (metrics) => metrics.distanceText,
      ),
    );

    return Stack(
      children: [
        Positioned(
          top: MediaQuery.paddingOf(context).top + 12,
          left: AppTheme.spacingMd,
          child: _FloatingCircleButton(
            icon: Icons.arrow_back,
            onPressed: onBackPressed,
          ),
        ),
        Positioned(
          top: MediaQuery.paddingOf(context).top + 12,
          left: 0,
          right: 0,
          child: Center(
            child: _StatusBubble(
              status: ride?.status,
              isSearching: flowState == BookingFlowState.searching,
              liveDistanceText: liveDistanceText,
            ),
          ),
        ),
        if (ride?.status == RideStatus.arrived ||
            ride?.status == RideStatus.inProgress)
          Positioned(
            top: MediaQuery.paddingOf(context).top + 12,
            right: AppTheme.spacingMd,
            child: _FloatingCircleButton(
              icon: Icons.share_outlined,
              gradient: AppColors.goldGradient,
              iconColor: Colors.white,
              onPressed: () => _shareRide(context, ref),
            ),
          ),
        if (arrivalTime != null &&
            (flowState == BookingFlowState.idle ||
                ride?.status == RideStatus.inProgress ||
                ride?.status == RideStatus.accepted))
          Positioned(
            top: MediaQuery.paddingOf(context).top + 60,
            left: 0,
            right: 0,
            child: Center(child: _ArrivalBubble(arrivalTime: arrivalTime!)),
          ),
      ],
    );
  }

  Future<void> _shareRide(BuildContext context, WidgetRef ref) async {
    final feedback = await ref
        .read(rideShareControllerProvider.notifier)
        .shareActiveRide();
    if (!context.mounted || feedback == null) return;

    switch (feedback.type) {
      case RideShareFeedbackType.success:
        AppSnackBar.showSuccess(context, feedback.message, atTop: true);
      case RideShareFeedbackType.info:
        AppSnackBar.showInfo(context, feedback.message, atTop: true);
      case RideShareFeedbackType.error:
        AppSnackBar.showError(context, feedback.message, atTop: true);
    }
  }
}

class _StatusBubble extends StatelessWidget {
  const _StatusBubble({
    this.status,
    this.isSearching = false,
    this.liveDistanceText,
  });

  final RideStatus? status;
  final bool isSearching;
  final String? liveDistanceText;

  @override
  Widget build(BuildContext context) {
    if (!isSearching && status == null) return const SizedBox.shrink();

    String text = '';
    if (isSearching) {
      text = 'Recherche d\'un chauffeur...';
    } else {
      switch (status) {
        case RideStatus.pending:
          text = 'Recherche d\'un chauffeur...';
        case RideStatus.accepted:
          final distance = _usableDistanceText;
          text = distance == null
              ? 'Chauffeur en route'
              : 'Chauffeur en route • $distance';
        case RideStatus.arrived:
          text = 'Chauffeur arrive';
        case RideStatus.inProgress:
          text = 'Course en cours';
        case RideStatus.completed:
          return const SizedBox.shrink();
        case RideStatus.cancelled:
          return const SizedBox.shrink();
        case null:
          return const SizedBox.shrink();
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius2xl),
        boxShadow: AppColors.shadowMd,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: AppTextStyles.small.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String? get _usableDistanceText {
    final distance = liveDistanceText?.trim();
    if (distance == null || distance.isEmpty || distance == '--') return null;
    return distance;
  }
}

class _ArrivalBubble extends StatelessWidget {
  const _ArrivalBubble({required this.arrivalTime});

  final String arrivalTime;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius2xl),
        boxShadow: AppColors.shadowMd,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.flag_rounded, color: AppColors.error, size: 18),
          const SizedBox(width: 6),
          Text(
            'arrivee a $arrivalTime',
            style: AppTextStyles.small.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _FloatingCircleButton extends StatelessWidget {
  const _FloatingCircleButton({
    required this.icon,
    required this.onPressed,
    this.gradient,
    this.iconColor,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final Gradient? gradient;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: context.colors.surface,
        gradient: gradient,
        shape: BoxShape.circle,
        boxShadow: AppColors.shadowMd,
      ),
      child: IconButton(
        icon: Icon(icon, color: iconColor ?? context.colors.textPrimary, size: 20),
        onPressed: onPressed,
      ),
    );
  }
}
