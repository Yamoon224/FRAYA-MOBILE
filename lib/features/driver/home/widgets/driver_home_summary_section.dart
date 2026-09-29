library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/widgets/fraya_button.dart';
import '../../auth/providers/driver_admin_status_gate.dart';
import '../../kyc/widgets/driver_kyc_status_banner.dart';
import '../../wallet/providers/driver_wallet_provider.dart';
import '../providers/driver_home_state.dart';
import 'driver_home_stats_grid.dart';

class DriverHomeSummarySection extends ConsumerWidget {
  const DriverHomeSummarySection({
    super.key,
    required this.state,
    required this.gate,
    required this.onOpenEarnings,
  });

  final DriverHomeState state;
  final DriverAdminStatusResult gate;
  final VoidCallback onOpenEarnings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletBalance = ref.watch(
      driverWalletProvider.select((state) => state.balance),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!gate.canGoOnline) ...[
          _BlockedBanner(gate: gate),
          const SizedBox(height: AppTheme.spacingMd),
        ] else if (state.hasError) ...[
          DriverKycStatusBanner(
            title: 'Action indisponible',
            message: state.errorMessage!,
            icon: Icons.error_outline_rounded,
            backgroundColor: context.colors.infoBackground,
            foregroundColor: AppColors.infoText,
          ),
          const SizedBox(height: AppTheme.spacingMd),
        ],
        DriverHomeStatsGrid(
          earnings: state.todayEarnings,
          walletBalance: walletBalance,
          rideCount: state.todayRideCount,
          onlineHours: state.todayOnlineHours,
        ),
        const SizedBox(height: AppTheme.spacingMd),
        LayoutBuilder(
          builder: (context, constraints) {
            final stackButtons =
                constraints.maxWidth < 360 ||
                context.layoutTier == LayoutTier.compact;
            final buttonSize = stackButtons
                ? FrayaButtonSize.md
                : FrayaButtonSize.sm;

            return FrayaButton(
              label: 'Mes recettes',
              variant: FrayaButtonVariant.outline,
              size: buttonSize,
              leftIcon: Icons.trending_up_rounded,
              onPressed: onOpenEarnings,
            );
          },
        ),
      ],
    );
  }
}

class _BlockedBanner extends StatelessWidget {
  const _BlockedBanner({required this.gate});

  final DriverAdminStatusResult gate;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DriverKycStatusBanner(
          title: _title,
          message:
              gate.blockingMessage ??
              'Une validation est requise avant de conduire.',
          icon: gate.needsKycSubmission
              ? Icons.assignment_late_outlined
              : Icons.info_outline_rounded,
          backgroundColor: gate.needsKycSubmission
              ? context.colors.infoBackground
              : context.colors.greyExtraLight,
          foregroundColor: gate.needsKycSubmission
              ? AppColors.infoText
              : context.colors.textPrimary,
        ),
        const SizedBox(height: AppTheme.spacingSm),
        FrayaButton(
          label: gate.needsKycSubmission
              ? 'Completer le dossier KYC'
              : gate.isKycPending
              ? 'Suivre mon dossier KYC'
              : gate.hasVehicleId
              ? 'Suivre la validation du véhicule'
              : 'Ajouter mon véhicule',
          variant: FrayaButtonVariant.outline,
          onPressed: () => context.pushNamed(
            gate.needsKycSubmission || gate.isKycPending
                ? RouteNames.driverKyc
                : RouteNames.driverVehicle,
          ),
        ),
      ],
    );
  }

  String get _title {
    if (gate.needsKycSubmission) {
      return 'Dossier KYC requis';
    }
    if (gate.isKycPending) {
      return 'Validation admin en cours';
    }
    if (!gate.hasVehicleId || !gate.isVehicleApproved) {
      return 'Validation véhicule requise';
    }
    return 'Conduite indisponible';
  }
}
