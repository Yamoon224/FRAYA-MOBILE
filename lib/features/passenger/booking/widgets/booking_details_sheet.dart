import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/directions_models.dart';
import '../../../../core/models/places_models.dart';
import '../../../../core/models/ride_category.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/fraya_button.dart';
import '../providers/payment_method_provider.dart';
import '../../../../shared/widgets/fraya_skeleton.dart';
import 'payment_method_selector.dart';
import 'toll_mention.dart';
import 'booking_summary_section.dart';
import 'category_selection_section.dart';

class BookingDetailsSheet extends ConsumerWidget {
  const BookingDetailsSheet({
    super.key,
    required this.directionsAsync,
    required this.destination,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.onConfirm,
    required this.scrollController,
    required this.selectedPaymentMethod,
    required this.onPaymentMethodSelected,
    required this.onRefreshRoutePricing,
    required this.onEditPickup,
    required this.onEditDestination,
  });
  final AsyncValue<DirectionsResult?> directionsAsync;
  final PlaceDetails? destination;
  final AsyncValue<List<RideCategory>> categories;
  final RideCategory? selectedCategory;
  final Function(RideCategory) onCategorySelected;
  final VoidCallback onConfirm;
  final ScrollController scrollController;
  final PaymentMethod selectedPaymentMethod;
  final Function(PaymentMethod) onPaymentMethodSelected;
  final Future<void> Function() onRefreshRoutePricing;
  final VoidCallback onEditPickup;
  final VoidCallback onEditDestination;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radius2xl),
        ),
        boxShadow: AppColors.shadowLg,
      ),
      child: RefreshIndicator(
        onRefresh: onRefreshRoutePricing,
        notificationPredicate: (n) => n.depth == 0,
        child: ListView(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            AppTheme.spacingLg,
            AppTheme.spacingMd,
            AppTheme.spacingLg,
            AppTheme.spacingLg + bottomInset,
          ),
          children: [
            const _SheetHandle(),
            const SizedBox(height: AppTheme.spacingMd),
            RouteSummarySection(
              directionsAsync: directionsAsync,
              destination: destination,
              onEditPickup: onEditPickup,
              onEditDestination: onEditDestination,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            categories.when(
              data: (cats) => CategorySelectionSection(
                categories: cats,
                selectedCategory: selectedCategory,
                onCategorySelected: onCategorySelected,
              ),
              loading: () => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonText(width: 180, height: 18),
                  const SizedBox(height: 8),
                  const SkeletonText(width: 140, height: 12),
                  const SizedBox(height: AppTheme.spacingMd),
                  for (int i = 0; i < 3; i++) const RideCategorySkeleton(),
                ],
              ),
              error: (_, _) => Text(
                'Erreur lors du chargement des gammes',
                style: AppTextStyles.body.copyWith(color: AppColors.error),
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            // if (selectedCategory != null && activeRoute != null) ...[
            //   PriceBreakdownTrigger(
            //     totalPrice: selectedCategory!.price,
            //     basePrice: 1500,
            //     distancePrice: (activeRoute.distanceValue / 1000 * 250).round(),
            //     durationPrice: (activeRoute.durationValue / 60 * 60).round(),
            //     distanceText: activeRoute.distanceText,
            //     durationText: '~${activeRoute.durationMinutes} min',
            //   ),
            //   const SizedBox(height: AppTheme.spacingMd),
            // ],
            PaymentMethodSelector(
              selectedMethod: selectedPaymentMethod,
              onMethodSelected: onPaymentMethodSelected,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            const TollMention(),
            const SizedBox(height: AppTheme.spacingMd),
            FrayaButton(
              label: 'Confirmer la course',
              onPressed: selectedCategory != null ? onConfirm : null,
              size: FrayaButtonSize.lg,
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBorder : AppColors.greyLight,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
