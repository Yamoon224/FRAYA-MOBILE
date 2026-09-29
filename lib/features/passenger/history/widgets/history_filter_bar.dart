import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/responsive.dart';
import '../providers/history_filter_provider.dart';

const _labels = <HistoryQuickFilter, String>{
  HistoryQuickFilter.today: "Aujourd'hui",
  HistoryQuickFilter.sevenDays: '7 jours',
  HistoryQuickFilter.thirtyDays: '30 jours',
  HistoryQuickFilter.all: 'Tout',
};

const _compactLabels = <HistoryQuickFilter, String>{
  HistoryQuickFilter.today: 'Auj.',
  HistoryQuickFilter.sevenDays: '7j',
  HistoryQuickFilter.thirtyDays: '30j',
  HistoryQuickFilter.all: 'Tout',
};

class HistoryFilterBar extends ConsumerWidget {
  const HistoryFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(historyFilterControllerProvider);
    final controller = ref.read(historyFilterControllerProvider.notifier);
    final hPad = context.horizontalPagePadding;
    final isCompact = context.layoutTier == LayoutTier.compact;

    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _QuickFilterRow(
            selected: state.customRange != null ? null : state.quickFilter,
            onSelected: controller.setQuickFilter,
            isCompact: isCompact,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          _PeriodButton(
            onTap: () => _pickRange(context, controller),
          ),
          if (state.customRange != null) ...[
            const SizedBox(height: AppTheme.spacingSm),
            _RangeChip(
              range: state.customRange!,
              onDeleted: controller.clearCustomRange,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickRange(
    BuildContext context,
    HistoryFilterController controller,
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
  });

  final HistoryQuickFilter? selected;
  final ValueChanged<HistoryQuickFilter> onSelected;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final filters = HistoryQuickFilter.values;
    final labelMap = isCompact ? _compactLabels : _labels;

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: context.colors.greyExtraLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          for (final filter in filters)
            Expanded(
              child: _QuickTab(
                label: labelMap[filter]!,
                isSelected: selected == filter,
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
    required this.onTap,
  });

  final String label;
  final bool isSelected;
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
  const _PeriodButton({required this.onTap});

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
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
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
            Icon(Icons.chevron_right_rounded, size: 18, color: iconColor),
          ],
        ),
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({
    required this.range,
    required this.onDeleted,
  });

  final DateTimeRange range;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    final bgColor = context.colors.isDark
        ? AppColors.darkSurfaceElevated
        : AppColors.primaryLight;
    final textColor = context.colors.isDark
        ? AppColors.darkTextPrimary
        : AppColors.primaryDark;
    final borderColor = context.colors.isDark
        ? AppColors.darkBorder
        : AppColors.primaryLight;

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingSm),
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
            child: Icon(Icons.close_rounded, size: 14, color: textColor),
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
