import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/address_formatter_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/providers/places_provider.dart';
import '../../../../shared/providers/location_provider.dart';
import '../../../../shared/providers/saved_places_provider.dart';
import 'search/search_header.dart';
import 'search/location_inputs.dart';
import 'search/suggestions_list.dart';

class DestinationSearchSheet extends ConsumerWidget {
  const DestinationSearchSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestionsAsync = ref.watch(placeSuggestionsProvider);
    final currentAddressAsync = ref.watch(passengerUserAddressProvider);
    final query = ref.watch(searchQueryProvider);
    final size = MediaQuery.sizeOf(context);
    final topInset = MediaQuery.paddingOf(context).top;
    var bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    context.visitAncestorElements((element) {
      final widget = element.widget;
      if (widget is MediaQuery && widget.data.viewInsets.bottom > bottomInset) {
        bottomInset = widget.data.viewInsets.bottom;
      }
      return true;
    });
    final maxWidth = context.contentMaxWidth;
    final heightRatio = context.responsiveValue<double>(
      compact: 0.95,
      phone: 0.92,
      largePhone: 0.9,
      tablet: 0.84,
    );
    final baseMinHeight = context.responsiveValue<double>(
      compact: 420,
      phone: 480,
      largePhone: 520,
      tablet: 560,
    );
    final maxHeight = (size.height - topInset - bottomInset - 8)
        .clamp(320.0, size.height)
        .toDouble();
    var minHeight = bottomInset > 0 ? 320.0 : baseMinHeight;
    if (minHeight > maxHeight) {
      minHeight = maxHeight;
    }
    final sheetHeight = (size.height * heightRatio)
        .clamp(minHeight, maxHeight)
        .toDouble();

    final currentAddress = currentAddressAsync.asData?.value;
    const formatter = AddressFormatterService();
    final formattedCurrent = currentAddress == null
        ? ''
        : formatter.normalize(currentAddress['formatted'] ?? '');
    final fallbackCurrent = currentAddress == null
        ? ''
        : formatter.format(
            formatter.fromComponents(
              quarter: currentAddress['quartier'],
              commune: currentAddress['commune'],
            ),
          );
    final String addressLabel = currentAddress != null
        ? (formattedCurrent.isNotEmpty
              ? formattedCurrent
              : (fallbackCurrent.isNotEmpty
                    ? fallbackCurrent
                    : 'Position actuelle'))
        : (currentAddressAsync.isLoading ? "" : "Position actuelle");

    Future<void> hardRefresh() async {
      ref
          .read(passengerLocationSnapshotRefreshTriggerProvider.notifier)
          .state++;
      ref.invalidate(passengerUserAddressProvider);
      ref.invalidate(nearbyLandmarksProvider);
      ref.invalidate(savedPlacesNotifierProvider);
      ref.invalidate(placeSuggestionsProvider);
      await ref.read(passengerUserAddressProvider.future);
      if (query.isEmpty) {
        await Future.wait([
          ref.read(nearbyLandmarksProvider.future),
          ref.read(savedPlacesNotifierProvider.future),
        ]);
      } else {
        await ref.read(placeSuggestionsProvider.future);
      }
    }

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Container(
              height: sheetHeight,
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radius2xl),
                ),
              ),
              child: Column(
                children: [
                  SearchHeader(
                    onBack: () {
                      ref.read(searchQueryProvider.notifier).clear();
                      Navigator.pop(context);
                    },
                  ),
                  LocationInputs(
                    currentAddress: addressLabel,
                    isLoading: currentAddressAsync.isLoading,
                  ),
                  Divider(height: 1, color: context.colors.greyLight),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: hardRefresh,
                      child: query.isEmpty
                          ? const DefaultPlacesList()
                          : SearchResultsList(
                              suggestionsAsync: suggestionsAsync,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
