library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/vehicle_ui_utils.dart';
import '../../../../domain/models/special_offer.dart';
import '../../../../shared/models/support_topic.dart';
import '../../../../shared/models/user_stats_view_data.dart';
import '../../../../shared/providers/special_offer_provider.dart';
import '../../../../shared/screens/support/support_screen.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/settings/legal_web_screen.dart';
import '../../../../shared/widgets/settings/logout_confirmation_dialog.dart';
import '../../../../shared/widgets/special_offer_card.dart';
import '../../auth/providers/driver_auth_provider.dart';
import '../../settings/providers/driver_settings_provider.dart';
import 'driver_drawer_sections.dart';

class DriverDrawer extends ConsumerWidget {
  const DriverDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userData =
        ref.watch(driverAuthProvider).userData ?? const <String, dynamic>{};
    final firstName =
        _text(userData['firstNames']) ??
        _text(userData['firstName']) ??
        'Chauffeur';
    final lastName = _text(userData['lastName']) ?? '';
    final fullName = '$firstName $lastName'.trim();
    final stats = UserStatsViewData.fromMap(userData);
    final photoUrl =
        _text(userData['profilePhoto']) ??
        _text(userData['photo']) ??
        _text(userData['avatar']);
    final rangeLabel = _vehicleRangeLabel(userData);
    final settings = ref.watch(driverSettingsProvider);
    final specialOffer = ref
        .watch(activeSpecialOfferProvider(SpecialOfferAudience.driver))
        .asData
        ?.value;
    final width = MediaQuery.sizeOf(context).width;
    final drawerWidth = context.isTablet
        ? 360.0
        : (width * 0.83).clamp(280.0, 380.0).toDouble();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppColors.darkBackground
        : const Color(0xFFF7F7F8);

    return Drawer(
      width: drawerWidth,
      backgroundColor: backgroundColor,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DriverIdentityHeader(
                      fullName: fullName,
                      stats: stats,
                      photoUrl: photoUrl,
                      rangeLabel: rangeLabel,
                    ),
                    const SizedBox(height: 18),
                    const Divider(),
                    const SizedBox(height: 18),
                    DriverDrawerItem(
                      icon: Icons.attach_money_rounded,
                      label: 'Mes recettes',
                      onTap: () => _go(context, RouteNames.driverEarnings),
                    ),
                    DriverDrawerItem(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Mon portefeuille',
                      onTap: () => _go(context, RouteNames.driverWallet),
                    ),
                    DriverDrawerItem(
                      icon: Icons.history_rounded,
                      label: 'Historique',
                      onTap: () => _go(context, RouteNames.driverHistory),
                    ),
                    DriverDrawerItem(
                      icon: Icons.person_outline_rounded,
                      label: 'Mon profil',
                      onTap: () => _go(context, RouteNames.driverProfile),
                    ),
                    DriverDrawerItem(
                      icon: Icons.settings_outlined,
                      label: 'Paramètres',
                      onTap: () => _go(context, RouteNames.driverSettings),
                    ),
                    DriverDrawerItem(
                      icon: Icons.info_outline_rounded,
                      label: 'À propos',
                      onTap: () => _openAbout(context),
                    ),
                    DriverDrawerToggleItem(
                      icon: Icons.dark_mode_outlined,
                      label: 'Mode sombre',
                      value: settings.darkModeEnabled,
                      onChanged: (_) => ref
                          .read(driverSettingsProvider.notifier)
                          .toggleDarkMode(),
                    ),
                    DriverDrawerItem(
                      icon: Icons.logout_rounded,
                      label: 'Déconnexion',
                      onTap: () => _logout(context, ref),
                    ),
                    const SizedBox(height: 18),
                    DriverHelpCard(
                      onPressed: () => _openSupport(context),
                    ),
                    if (specialOffer != null) ...[
                      const SizedBox(height: 18),
                      SpecialOfferCard(
                        offer: specialOffer,
                        onShare: () => _shareOffer(context, ref, specialOffer),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _go(BuildContext context, String routeName) {
    Navigator.of(context).pop();
    context.pushNamed(routeName);
  }

  void _openAbout(BuildContext context) {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const LegalWebScreen(
          title: 'À propos',
          url: 'https://manager.frayataxi.ci/abouts',
        ),
      ),
    );
  }

  void _openSupport(BuildContext context) {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const SupportScreen(
          audience: SupportAudience.driver,
          title: 'Support chauffeur',
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showLogoutConfirmationDialog(context);
    if (!confirmed) return;
    if (context.mounted) {
      Navigator.of(context).pop();
    }
    await ref.read(driverAuthProvider.notifier).logout();
  }

  Future<void> _shareOffer(
    BuildContext context,
    WidgetRef ref,
    SpecialOffer offer,
  ) async {
    final errorMessage = await ref
        .read(specialOfferShareControllerProvider)
        .shareOffer(offer);
    if (!context.mounted || errorMessage == null) return;
    AppSnackBar.showError(context, errorMessage);
  }

  String? _text(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty || text == 'null') return null;
    return text;
  }

  String? _vehicleRangeLabel(Map<String, dynamic> userData) {
    final vehicle =
        _mapValue(userData['vehicle']) ??
        _mapValue(userData['vehicule']) ??
        _firstMap(userData['vehicles']);
    final range =
        _text(vehicle?['range']) ??
        _text(vehicle?['requestedRange']) ??
        _text(userData['range']) ??
        _text(userData['requestedRange']);
    return range == null ? null : VehicleUiUtils.rangeLabel(range);
  }

  Map<String, dynamic>? _firstMap(dynamic value) {
    if (value is! List) return null;
    for (final item in value) {
      final map = _mapValue(item);
      if (map != null) return map;
    }
    return null;
  }

  Map<String, dynamic>? _mapValue(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }
}
