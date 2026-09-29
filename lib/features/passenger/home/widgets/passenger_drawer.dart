import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../domain/models/special_offer.dart';
import '../../../../shared/models/user_stats_view_data.dart';
import '../../../../shared/providers/special_offer_provider.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/special_offer_card.dart';
import '../../../../shared/widgets/settings/legal_web_screen.dart';
import '../../auth/providers/passenger_auth_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../settings/providers/passenger_settings_provider.dart';
import 'passenger_drawer_sections.dart';

class PassengerDrawer extends ConsumerStatefulWidget {
  const PassengerDrawer({super.key});

  @override
  ConsumerState<PassengerDrawer> createState() => _PassengerDrawerState();
}

class _PassengerDrawerState extends ConsumerState<PassengerDrawer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(passengerSettingsProvider);
    final authState = ref.watch(passengerAuthProvider);
    final userData = authState.userData;
    final profileAsync = ref.watch(passengerProfileProvider);
    final specialOfferAsync = ref.watch(
      activeSpecialOfferProvider(SpecialOfferAudience.passenger),
    );
    final profileStats = profileAsync.maybeWhen(
      data: (profile) => UserStatsViewData(
        rating: profile.rating,
        ridesCount: profile.ridesCount,
      ),
      orElse: () => UserStatsViewData.fromMap(userData),
    );
    final profilePhotoUrl = profileAsync.asData?.value.photoUrl;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final drawerWidth =
        (screenWidth *
                context.responsiveValue<double>(
                  compact: 0.9,
                  phone: 0.86,
                  largePhone: 0.8,
                  tablet: 0.5,
                ))
            .clamp(280, 420);
    final horizontalPadding = context.responsiveValue<double>(
      compact: AppTheme.spacingMd,
      phone: AppTheme.spacingLg,
      largePhone: AppTheme.spacingLg,
      tablet: 28,
    );
    final surfaceColor = context.colors.surface;
    final dividerColor = context.colors.greyLight;

    return Drawer(
      width: drawerWidth.toDouble(),
      backgroundColor: surfaceColor,
      elevation: 16,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: AppTheme.spacingLg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _animatedItem(
                PassengerDrawerUserInfo(
                  userData: userData,
                  stats: profileStats,
                  profilePhotoUrl: profilePhotoUrl,
                ),
                0,
              ),
              const SizedBox(height: AppTheme.spacingLg),
              _animatedItem(Divider(color: dividerColor, height: 1), 1),
              const SizedBox(height: AppTheme.spacingLg),
              _animatedItem(
                PassengerDrawerMenuItem(
                  icon: Icons.history_rounded,
                  title: 'Mes courses',
                  onTap: () => _openRoute(context, RoutePaths.history),
                ),
                2,
              ),
              const SizedBox(height: AppTheme.spacingMd),
              _animatedItem(
                PassengerDrawerMenuItem(
                  icon: Icons.person_outline,
                  title: 'Profil',
                  onTap: () => _openRoute(context, RoutePaths.profile),
                ),
                3,
              ),
              const SizedBox(height: AppTheme.spacingMd),
              _animatedItem(
                PassengerDrawerMenuItem(
                  icon: Icons.settings_outlined,
                  title: 'Paramètres',
                  onTap: () => _openRoute(context, RoutePaths.settings),
                ),
                4,
              ),
              const SizedBox(height: AppTheme.spacingMd),
              _animatedItem(
                PassengerDrawerToggleItem(
                  icon: Icons.dark_mode_outlined,
                  title: 'Mode sombre',
                  value: settings.darkModeEnabled,
                  onChanged: (_) => ref
                      .read(passengerSettingsProvider.notifier)
                      .toggleDarkMode(),
                ),
                5,
              ),
              const SizedBox(height: AppTheme.spacingLg),
              _animatedItem(Divider(color: dividerColor, height: 1), 6),
              const SizedBox(height: AppTheme.spacingLg),
              _animatedItem(_buildAboutLink(), 7),
              const Spacer(),
              if (specialOfferAsync.asData?.value case final offer?)
                _animatedItem(
                  SpecialOfferCard(
                    offer: offer,
                    onShare: () => _shareSpecialOffer(context, offer),
                  ),
                  8,
                ),
              const SizedBox(height: AppTheme.spacingMd),
            ],
          ),
        ),
      ),
    );
  }

  Widget _animatedItem(Widget child, int index) {
    final start = (index * 0.1).clamp(0.0, 1.0);
    final end = (start + 0.5).clamp(0.0, 1.0);
    final animation = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(-0.15, 0),
        end: Offset.zero,
      ).animate(animation),
      child: FadeTransition(opacity: animation, child: child),
    );
  }

  Widget _buildAboutLink() {
    return Builder(
      builder: (context) {
        final textColor = context.colors.textPrimary;
        return InkWell(
          onTap: () {
            Navigator.pop(context);
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const LegalWebScreen(
                  title: 'À propos',
                  url: 'https://manager.frayataxi.ci/abouts',
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'A propos',
              style: AppTextStyles.body.copyWith(
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      },
    );
  }

  void _openRoute(BuildContext context, String routePath) {
    Navigator.pop(context);
    context.push(routePath);
  }

  Future<void> _shareSpecialOffer(
    BuildContext context,
    SpecialOffer offer,
  ) async {
    final errorMessage = await ref
        .read(specialOfferShareControllerProvider)
        .shareOffer(offer);
    if (!mounted || !context.mounted || errorMessage == null) return;
    AppSnackBar.showError(context, errorMessage);
  }
}
