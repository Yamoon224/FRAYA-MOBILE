library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/fraya_button.dart';
import '../../auth/providers/driver_admin_status_gate.dart';
import '../../auth/providers/driver_auth_provider.dart';
import '../../profile/providers/driver_profile_view_data_resolver.dart';
import '../../profile/widgets/driver_profile_vehicle_card.dart';
import '../../settings/providers/driver_settings_provider.dart';

class DriverVehiclePendingScreen extends ConsumerStatefulWidget {
  const DriverVehiclePendingScreen({super.key});

  @override
  ConsumerState<DriverVehiclePendingScreen> createState() =>
      _DriverVehiclePendingScreenState();
}

class _DriverVehiclePendingScreenState
    extends ConsumerState<DriverVehiclePendingScreen> {
  bool _isRefreshing = false;
  Timer? _pollingTimer;
  int? _lastSeenNotifId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initNotifBaseline());
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _pollNotifications(),
    );
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _initNotifBaseline() async {
    try {
      final service = ref.read(driverSettingsServiceProvider);
      final notifs = await service.getOwnNotifications();
      final adminNotifs = notifs
          .where((n) => n['sentBySidUserId'] == null)
          .toList();
      if (adminNotifs.isNotEmpty) {
        final maxId = adminNotifs
            .map((n) => (n['id'] as num?)?.toInt() ?? 0)
            .reduce((a, b) => a > b ? a : b);
        if (mounted) setState(() => _lastSeenNotifId = maxId);
      } else {
        if (mounted) setState(() => _lastSeenNotifId = 0);
      }
    } catch (_) {
      if (mounted) setState(() => _lastSeenNotifId = 0);
    }
  }

  Future<void> _pollNotifications() async {
    if (!mounted || _lastSeenNotifId == null) return;
    try {
      final service = ref.read(driverSettingsServiceProvider);
      final notifs = await service.getOwnNotifications();
      final newAdminNotifs = notifs
          .where(
            (n) =>
                n['sentBySidUserId'] == null &&
                ((n['id'] as num?)?.toInt() ?? 0) > _lastSeenNotifId!,
          )
          .toList();

      if (newAdminNotifs.isEmpty || !mounted) return;

      final maxId = newAdminNotifs
          .map((n) => (n['id'] as num?)?.toInt() ?? 0)
          .reduce((a, b) => a > b ? a : b);
      setState(() => _lastSeenNotifId = maxId);

      final latest = newAdminNotifs.first;
      final content = (latest['content'] as String? ?? '').trim();
      final title = (latest['title'] as String? ?? '').toLowerCase();

      if (content.isNotEmpty && mounted) {
        final isRejection = title.contains('refus') || title.contains('rejet');
        if (isRejection) {
          AppSnackBar.showError(context, content);
        } else {
          AppSnackBar.showSuccess(context, content);
        }
      }

      await ref.read(driverAuthProvider.notifier).refreshProfile();
    } catch (_) {
      // polling silencieux — pas d'alerte en cas d'erreur réseau
    }
  }

  Future<void> _refreshStatus() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    await ref.read(driverAuthProvider.notifier).refreshProfile();
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(driverAuthProvider).userData;
    final gate = DriverAdminStatusGate.fromUserData(userData);
    final vehicle = DriverProfileViewDataResolver.fromUserData(
      userData ?? const <String, dynamic>{},
    ).vehicle;
    final backgroundColor = context.colors.background;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshStatus,
          color: AppColors.primaryDark,
          child: context.responsiveBody(
            SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: context.screenPadding,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      MediaQuery.sizeOf(context).height -
                      MediaQuery.paddingOf(context).vertical -
                      32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset('assets/images/logo_fraya.png', height: 40),
                    const SizedBox(height: AppTheme.spacing2xl),
                    _StatusHero(gate: gate),
                    const SizedBox(height: AppTheme.spacingLg),
                    _StatusList(gate: gate),
                    if (vehicle != null) ...[
                      const SizedBox(height: AppTheme.spacingLg),
                      Text('Vehicule soumis', style: context.textH1),
                      const SizedBox(height: AppTheme.spacingSm),
                      DriverProfileVehicleCard(vehicle: vehicle),
                    ],
                    const SizedBox(height: AppTheme.spacingXl),
                    FrayaButton(
                      label: 'Actualiser le statut',
                      onPressed: _isRefreshing ? null : _refreshStatus,
                      isLoading: _isRefreshing,
                      leftIcon: Icons.refresh_rounded,
                    ),
                    const SizedBox(height: AppTheme.spacing2xl),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusHero extends StatelessWidget {
  const _StatusHero({required this.gate});

  final DriverAdminStatusResult gate;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: context.colors.surfacePressed,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppColors.primaryLight),
        boxShadow: AppColors.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.verified_user_outlined,
            size: 44,
            color: AppColors.primaryDark,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text('Dossier en cours de validation', style: context.textH1),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            _message,
            style: context.textBody.copyWith(color: context.colors.textSecondary),
          ),
        ],
      ),
    );
  }

  String get _message {
    if (gate.isKycPending &&
        gate.vehicleState == DriverAdminApprovalState.pending) {
      return 'Vos documents chauffeur et véhicule ont bien été envoyés. '
          'Notre équipe les vérifie et vous pourrez conduire dès validation.';
    }
    if (gate.isKycPending) {
      return 'Votre dossier chauffeur est en cours de vérification. '
          'Merci de patienter pendant la validation admin.';
    }
    return 'Votre véhicule a bien été soumis. '
        'Notre équipe vérifie les documents avant d’activer votre profil.';
  }
}

class _StatusList extends StatelessWidget {
  const _StatusList({required this.gate});

  final DriverAdminStatusResult gate;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _StatusRow(label: 'Dossier KYC', state: gate.kycState),
        const SizedBox(height: AppTheme.spacingSm),
        _StatusRow(label: 'Dossier véhicule', state: gate.vehicleState),
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.state});

  final String label;
  final DriverAdminApprovalState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: context.textH3)),
          _StatusBadge(state: state),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.state});

  final DriverAdminApprovalState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (label, bg, fg) = switch (state) {
      DriverAdminApprovalState.approved => (
        'Validé',
        colors.successBackground,
        AppColors.successText,
      ),
      DriverAdminApprovalState.pending => (
        'En attente',
        colors.infoBackground,
        AppColors.infoText,
      ),
      DriverAdminApprovalState.rejected => (
        'Rejeté',
        const Color(0xFFFEE2E2),
        AppColors.error,
      ),
      _ => (
        'Non soumis',
        colors.greyExtraLight,
        colors.textSecondary,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: context.textSmall.copyWith(color: fg),
      ),
    );
  }
}
