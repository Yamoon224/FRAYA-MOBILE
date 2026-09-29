library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../domain/models/driver_ride.dart';
import '../models/driver_history_day_section.dart';
import '../providers/driver_history_filter_provider.dart';
import '../providers/driver_history_provider.dart';
import '../widgets/driver_history_feedback_cards.dart';
import '../widgets/driver_history_filter_bar.dart';
import '../widgets/driver_history_list_section.dart';
import '../widgets/driver_history_stats_header.dart';

class DriverHistoryScreen extends ConsumerStatefulWidget {
  const DriverHistoryScreen({super.key});

  @override
  ConsumerState<DriverHistoryScreen> createState() =>
      _DriverHistoryScreenState();
}

class _DriverHistoryScreenState extends ConsumerState<DriverHistoryScreen> {
  int _selectedIndex = 0;

  Future<void> _hardRefreshHistory() async {
    if (_selectedIndex != 0) {
      setState(() => _selectedIndex = 0);
    }
    ref.invalidate(driverHistoryFilterControllerProvider);
    ref.invalidate(driverHistoryRidesProvider);
    try {
      await ref.read(driverHistoryRidesProvider.future);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final historyAsync = ref.watch(driverHistoryRidesProvider);
    final todayStats = ref.watch(todayDriverHistoryStatsProvider);
    final historyStats = ref.watch(allDriverHistoryStatsProvider);
    final filteredStats = ref.watch(filteredDriverHistoryStatsProvider);
    final todayRides = ref.watch(todayDriverHistoryRidesProvider);
    final historySections = ref.watch(driverHistorySectionsProvider);
    final showLoading = historyAsync.isLoading && !historyAsync.hasValue;
    final showError = historyAsync.hasError && !historyAsync.hasValue;

    final bgColor = context.colors.background;
    final surfaceColor = context.colors.surface;
    final titleColor = context.colors.textPrimary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Historique',
          style: AppTextStyles.h1.copyWith(
            fontSize: 20,
            color: titleColor,
          ),
        ),
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: _CircleIconButton(
            icon: Icons.arrow_back_rounded,
            isDark: isDark,
            surfaceColor: surfaceColor,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      body: SafeArea(
        child: context.responsiveBody(
          RefreshIndicator(
            onRefresh: _hardRefreshHistory,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: context.listViewPadding,
              children: [
                _HistoryTabs(
                  selectedIndex: _selectedIndex,
                  isDark: isDark,
                  onSelected: (index) => setState(() => _selectedIndex = index),
                ),
                const SizedBox(height: AppTheme.spacingLg),
                DriverHistoryStatsHeader(
                  todayStats: todayStats,
                  historyStats: _selectedIndex == 1
                      ? filteredStats
                      : historyStats,
                  historyLabel: _selectedIndex == 1 ? 'Période' : 'Historique',
                ),
                const SizedBox(height: AppTheme.spacingLg),
                if (_selectedIndex == 1) const DriverHistoryFilterBar(),
                if (showError)
                  DriverHistoryErrorCard(
                    message: _toErrorMessage(historyAsync.error),
                    onRefresh: _hardRefreshHistory,
                  )
                else if (showLoading)
                  const DriverHistoryLoadingView()
                else
                  DriverHistoryListSection(
                    title: _selectedIndex == 0
                        ? 'Courses du jour'
                        : 'Historique des courses',
                    sections: _selectedIndex == 0
                        ? _buildTodaySections(todayRides)
                        : historySections,
                    emptyMessage: _selectedIndex == 0
                        ? 'Aucune course terminée ou annulée aujourd\'hui.'
                        : 'Aucune course ne correspond à cette période.',
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<DriverHistoryDaySection> _buildTodaySections(
    List<DriverRide> todayRides,
  ) {
    if (todayRides.isEmpty) {
      return const [];
    }
    return [
      DriverHistoryDaySection(
        day: DateTime.now(),
        title: 'Aujourd\'hui',
        rides: todayRides,
      ),
    ];
  }

  String _toErrorMessage(Object? error) {
    final raw = error?.toString().trim() ?? '';
    if (raw.startsWith('Exception: ')) {
      return raw.substring('Exception: '.length).trim();
    }
    return raw.isNotEmpty
        ? raw
        : 'Impossible de charger l\'historique chauffeur pour le moment.';
  }
}

class _HistoryTabs extends StatelessWidget {
  const _HistoryTabs({
    required this.selectedIndex,
    required this.isDark,
    required this.onSelected,
  });

  final int selectedIndex;
  final bool isDark;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    const labels = ['Aujourd\'hui', 'Historique'];
    final deselectedColor = context.colors.surfaceElevated;
    final deselectedTextColor = context.colors.textSecondary;

    return Row(
      children: List<Widget>.generate(labels.length, (index) {
        final isSelected = index == selectedIndex;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index == labels.length - 1 ? 0 : AppTheme.spacingSm,
            ),
            child: GestureDetector(
              key: ValueKey('driver-history-tab-$index'),
              onTap: () => onSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: context.responsiveValue<double>(
                  compact: 40,
                  phone: AppTheme.tabButtonHeight,
                  largePhone: AppTheme.tabButtonHeight,
                  tablet: AppTheme.tabButtonHeightTablet,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.goldGradient : null,
                  color: isSelected ? null : deselectedColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isSelected ? AppColors.shadowYellowSm : null,
                ),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      labels[index],
                      style: AppTextStyles.buttonSmall.copyWith(
                        color: isSelected
                            ? context.colors.textPrimary
                            : deselectedTextColor,
                      ),
                      maxLines: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.isDark,
    required this.surfaceColor,
    required this.onPressed,
  });

  final IconData icon;
  final bool isDark;
  final Color surfaceColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final iconColor = context.colors.textPrimary;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface,
        shape: BoxShape.circle,
        boxShadow: isDark ? null : AppColors.shadowMd,
        border: isDark ? Border.all(color: AppColors.darkBorder) : null,
      ),
      child: IconButton(
        icon: Icon(icon, color: iconColor),
        onPressed: onPressed,
      ),
    );
  }
}
