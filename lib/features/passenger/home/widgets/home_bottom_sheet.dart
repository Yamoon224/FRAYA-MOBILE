import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/providers/recent_places_provider.dart';
import '../../../../shared/widgets/fraya_skeleton.dart';
import '../providers/home_controller.dart';
import 'address_search_sheet_launcher.dart';
import 'recent_place_tile.dart';

class HomeBottomSheet extends ConsumerWidget {
  const HomeBottomSheet({super.key, required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentPlacesAsync = ref.watch(recentPlacesListProvider);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final horizontalPadding = context.responsiveValue<double>(
      compact: AppTheme.spacingMd,
      phone: AppTheme.spacingLg,
      largePhone: AppTheme.spacingLg,
      tablet: 28,
    );
    final searchVerticalPadding = context.responsiveValue<double>(
      compact: 12,
      phone: 14,
      largePhone: 14,
      tablet: 16,
    );
    final searchIconSize = context.responsiveValue<double>(
      compact: 20,
      phone: 22,
      largePhone: 22,
      tablet: 24,
    );

    final surfaceColor = context.colors.surface;
    final handleColor = context.colors.greyLight;
    final searchBgColor = context.colors.greyExtraLight;
    final searchIconColor = context.colors.textSecondary;
    final placeholderColor = context.colors.textTertiary;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radius2xl),
        ),
        boxShadow: AppColors.shadowLg,
      ),
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        AppTheme.spacingMd,
        horizontalPadding,
        AppTheme.spacingLg + bottomInset,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: handleColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          GestureDetector(
            onTap: () {
              final homeController = ref.read(passengerHomeProvider.notifier);
              if (!homeController.ensurePassengerLocationReady(context)) {
                return;
              }
              showPassengerAddressSearchSheet(context, ref);
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: searchVerticalPadding,
              ),
              decoration: BoxDecoration(
                color: searchBgColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: searchIconColor,
                    size: searchIconSize,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Où allez-vous ?',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        color: placeholderColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(recentPlacesListProvider);
                await ref.read(recentPlacesListProvider.future);
              },
              child: SingleChildScrollView(
                controller: scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Récents', style: AppTextStyles.h4),
                    const SizedBox(height: AppTheme.spacingSm),
                    recentPlacesAsync.when(
                      data: (places) {
                        if (places.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'Aucune adresse récente',
                              style: AppTextStyles.small.copyWith(
                                color: placeholderColor,
                              ),
                            ),
                          );
                        }
                        return Column(
                          children: places
                              .map(
                                (place) => RecentPlaceTile(
                                  title: place.name,
                                  subtitle: place.address,
                                  onTap: () => ref
                                      .read(passengerHomeProvider.notifier)
                                      .selectRecentPlace(context, place),
                                ),
                              )
                              .toList(),
                        );
                      },
                      loading: () => Column(
                        children: [
                          for (int i = 0; i < 3; i++) ...[
                            const RecentLocationSkeleton(),
                            if (i < 2) const SizedBox(height: 16),
                          ],
                        ],
                      ),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
