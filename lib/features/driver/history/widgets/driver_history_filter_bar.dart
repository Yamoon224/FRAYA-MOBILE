library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/responsive.dart';
import '../providers/driver_history_filter_provider.dart';

const _labels = <DriverHistoryQuickFilter, String>{
  DriverHistoryQuickFilter.today: "Aujourd'hui",
  DriverHistoryQuickFilter.sevenDays: '7 jours',
  DriverHistoryQuickFilter.thirtyDays: '30 jours',
  DriverHistoryQuickFilter.all: 'Tout',
};

const _compactLabels = <DriverHistoryQuickFilter, String>{
  DriverHistoryQuickFilter.today: 'Auj.',
  DriverHistoryQuickFilter.sevenDays: '7j',
  DriverHistoryQuickFilter.thirtyDays: '30j',
  DriverHistoryQuickFilter.all: 'Tout',
};

class DriverHistoryFilterBar extends ConsumerWidget {
  const DriverHistoryFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(driverHistoryFilterControllerProvider);
    final controller =
        ref.read(driverHistoryFilterControllerProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompact = context.layoutTier == LayoutTier.compact;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _QuickFilterRow(
            selected:
                state.customRange != null ? null : state.quickFilter,
            onSelected: controller.setQuickFilter,
            isCompact: isCompact,
            isDark: isDark,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          _PeriodButton(
            isDark: isDark,
            onTap: () => _pickRange(context, controller),
          ),
          if (state.customRange != null) ...[
            const SizedBox(height: AppTheme.spacingSm),
            _RangeChip(
              range: state.customRange!,
              isDark: isDark,
              onDeleted: controller.clearCustomRange,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickRange(
    BuildContext context,
    DriverHistoryFilterController controller,
  ) async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      locale: const Locale('fr', 'FR'),
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
      currentDate: now,
      saveText: 'Appliquer',
      helpText: 'Choisir une période',
    );
    if (range != null) {
      controller.setCustomRange(range);
    }
  }
}

class _QuickFilterRow extends StatelessWidget {
  const _QuickFilterRow({
    required this.selected,
    required this.onSelected,
    required this.isCompact,
    required this.isDark,
  });

  final DriverHistoryQuickFilter? selected;
  final ValueChanged<DriverHistoryQuickFilter> onSelected;
  final bool isCompact;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final filters = DriverHistoryQuickFilter.values;
    final labelMap = isCompact ? _compactLabels : _labels;

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: context.colors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          for (final filter in filters)
            Expanded(
              child: _QuickTab(
                label: labelMap[filter]!,
                isSelected: selected == filter,
                isDark: isDark,
                onTap: () => onSelected(filter),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickTab extends StatelessWidget {
  const _QuickTab({
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = isSelected
        ? AppColors.primaryDark
        : context.colors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryLight.withValues(alpha: 0.6),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: AppTextStyles.small.copyWith(
                color: textColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              maxLines: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _PeriodButton extends StatelessWidget {
  const _PeriodButton({required this.isDark, required this.onTap});

  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bgColor = context.colors.greyExtraLight;
    final textColor = context.colors.textSecondary;
    final iconColor = context.colors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        padding:
            const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Row(
          children: [
            Icon(Icons.date_range_outlined, size: 18, color: iconColor),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: Text(
                'Période personnalisée',
                style: AppTextStyles.small.copyWith(color: textColor),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: iconColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({
    required this.range,
    required this.isDark,
    required this.onDeleted,
  });

  final DateTimeRange range;
  final bool isDark;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    final bgColor = AppColors.primaryLight;
    final textColor = AppColors.primaryDark;
    final borderColor = AppColors.primaryLight;

    return Container(
      height: 36,
      padding:
          const EdgeInsets.symmetric(horizontal: AppTheme.spacingSm),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.date_range_outlined, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(
            _formatRange(range),
            style: AppTextStyles.small.copyWith(
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onDeleted,
            behavior: HitTestBehavior.opaque,
            child: Icon(
              Icons.close_rounded,
              size: 14,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatRange(DateTimeRange range) {
    final fmt = DateFormat('dd MMM', 'fr_FR');
    return '${fmt.format(range.start)} – ${fmt.format(range.end)}';
  }
}
