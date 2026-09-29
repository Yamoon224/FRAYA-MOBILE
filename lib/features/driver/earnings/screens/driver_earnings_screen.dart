library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/widgets/sheet_handle.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../history/providers/driver_history_provider.dart';
import '../../history/widgets/driver_history_feedback_cards.dart';
import '../models/driver_earnings_summary.dart';
import '../providers/driver_earnings_provider.dart';
import '../services/driver_earnings_export_service.dart';
import '../widgets/driver_earnings_recent_rides_section.dart';
import '../widgets/driver_earnings_summary_cards.dart';

class DriverEarningsScreen extends ConsumerWidget {
  const DriverEarningsScreen({super.key});

  Future<void> _hardRefreshEarnings(WidgetRef ref) async {
    ref
        .read(driverEarningsFilterProvider.notifier)
        .setPeriod(DriverEarningsPeriod.today);
    ref.invalidate(driverHistoryRidesProvider);
    try {
      await ref.read(driverHistoryRidesProvider.future);
    } catch (_) {}
  }

  Future<void> _exportEarnings(BuildContext context, WidgetRef ref) async {
    final rides = ref.read(filteredDriverEarningsRidesProvider);
    if (rides.isEmpty) {
      AppSnackBar.showInfo(
        context,
        'Aucune course terminée à exporter sur cette période.',
      );
      return;
    }

    final filter = ref.read(driverEarningsFilterProvider);
    final summary = ref.read(driverEarningsSummaryProvider);
    final period = _exportPeriodFor(filter);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) =>
          _EarningsExportConfirmationDialog(period: period, summary: summary),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }

    try {
      final result = await ref
          .read(driverEarningsExportServiceProvider)
          .exportCsv(
            DriverEarningsExportRequest(
              rides: rides,
              summary: summary,
              period: period,
            ),
          );
      if (!context.mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(result.path, name: result.fileName, mimeType: 'text/csv'),
          ],
          subject: 'Récapitulatif des recettes Fraya',
          text: DriverEarningsExportService.disclaimer,
        ),
      );
      if (!context.mounted) return;
      AppSnackBar.showSuccess(context, 'Export des recettes prêt à partager.');
    } catch (_) {
      if (!context.mounted) return;
      AppSnackBar.showError(
        context,
        'Impossible de générer l\'export des recettes pour le moment.',
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(driverHistoryRidesProvider);
    final filter = ref.watch(driverEarningsFilterProvider);
    final controller = ref.read(driverEarningsFilterProvider.notifier);
    final summary = ref.watch(driverEarningsSummaryProvider);
    final sections = ref.watch(driverEarningsSectionsProvider);
    final showLoading = historyAsync.isLoading && !historyAsync.hasValue;
    final showError = historyAsync.hasError && !historyAsync.hasValue;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = context.colors.background;
    final sheetColor = context.colors.surface;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Mes recettes',
          style: AppTextStyles.h1.copyWith(fontSize: 20),
        ),
        centerTitle: true,
        leading: _CircleIconButton(
          icon: Icons.arrow_back_rounded,
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _CircleIconButton(
              icon: Icons.file_download_outlined,
              onPressed: showLoading || showError
                  ? null
                  : () => _exportEarnings(context, ref),
            ),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          final defaultSize = context.responsiveValue<double>(
            compact: 0.80,
            phone: 0.75,
            largePhone: 0.72,
            tablet: 0.65,
          );
          final minSize = context.responsiveValue<double>(
            compact: 0.22,
            phone: 0.22,
            largePhone: 0.20,
            tablet: 0.18,
          );
          return Stack(
            children: [
              Container(color: backgroundColor),
              DraggableScrollableSheet(
                initialChildSize: defaultSize,
                minChildSize: minSize,
                maxChildSize: 0.98,
                snap: true,
                snapSizes: [defaultSize],
                builder: (context, scrollController) {
                  final bottomInset = MediaQuery.paddingOf(context).bottom;
                  return Container(
                    decoration: BoxDecoration(
                      color: sheetColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppTheme.radius2xl),
                      ),
                      boxShadow: isDark ? null : AppColors.shadowLg,
                    ),
                    child: RefreshIndicator(
                      onRefresh: () => _hardRefreshEarnings(ref),
                      child: ListView(
                        controller: scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          context.horizontalPagePadding,
                          AppTheme.spacingMd,
                          context.horizontalPagePadding,
                          AppTheme.spacingLg + bottomInset,
                        ),
                        children: [
                          const SheetHandle(),
                          const SizedBox(height: AppTheme.spacingMd),
                          _PeriodTabs(
                            selectedPeriod: filter.period,
                            onSelected: (period) =>
                                controller.setPeriod(period),
                          ),
                          if (filter.period ==
                              DriverEarningsPeriod.thirtyDays) ...[
                            const SizedBox(height: AppTheme.spacingMd),
                            _EarningsSubFilterBar(
                              filter: filter,
                              controller: controller,
                            ),
                          ],
                          const SizedBox(height: AppTheme.spacingLg),
                          if (showError)
                            DriverHistoryErrorCard(
                              message: _toErrorMessage(historyAsync.error),
                              onRefresh: () => _hardRefreshEarnings(ref),
                            )
                          else if (showLoading)
                            const DriverHistoryLoadingView()
                          else ...[
                            DriverEarningsSummaryCards(summary: summary),
                            const SizedBox(height: AppTheme.spacingLg),
                            DriverEarningsRecentRidesSection(
                              title: _sectionTitle(filter),
                              sections: sections,
                              emptyMessage: _emptyMessage(filter),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  String _sectionTitle(DriverEarningsFilterState filter) {
    if (filter.period == DriverEarningsPeriod.thirtyDays &&
        filter.customRange != null) {
      final fmt = DateFormat('dd MMM', 'fr_FR');
      return 'Courses du ${fmt.format(filter.customRange!.start)}'
          ' au ${fmt.format(filter.customRange!.end)}';
    }
    return switch (filter.period) {
      DriverEarningsPeriod.today => 'Courses d\'aujourd\'hui',
      DriverEarningsPeriod.sevenDays => 'Courses des 7 derniers jours',
      DriverEarningsPeriod.thirtyDays => 'Courses des 30 derniers jours',
    };
  }

  String _emptyMessage(DriverEarningsFilterState filter) {
    if (filter.period == DriverEarningsPeriod.thirtyDays &&
        filter.customRange != null) {
      return 'Aucune course terminée sur la période sélectionnée.';
    }
    return switch (filter.period) {
      DriverEarningsPeriod.today =>
        'Aucune course terminée aujourd\'hui pour cette vue.',
      DriverEarningsPeriod.sevenDays =>
        'Aucune course terminée sur les 7 derniers jours.',
      DriverEarningsPeriod.thirtyDays =>
        'Aucune course terminée sur les 30 derniers jours.',
    };
  }

  String _toErrorMessage(Object? error) {
    final raw = error?.toString().trim() ?? '';
    if (raw.startsWith('Exception: ')) {
      return raw.substring('Exception: '.length).trim();
    }
    return raw.isNotEmpty
        ? raw
        : 'Impossible de charger l\'historique des gains pour le moment.';
  }

  DriverEarningsExportPeriod _exportPeriodFor(
    DriverEarningsFilterState filter,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final customRange = filter.customRange;
    if (customRange != null) {
      final start = _startOfDay(customRange.start);
      final end = _startOfDay(customRange.end);
      return DriverEarningsExportPeriod(
        label: _rangeLabel(start, end),
        start: start,
        end: end,
      );
    }

    return switch (filter.period) {
      DriverEarningsPeriod.today => DriverEarningsExportPeriod(
        label: _singleDayLabel('Aujourd\'hui', today),
        start: today,
        end: today,
      ),
      DriverEarningsPeriod.sevenDays => DriverEarningsExportPeriod(
        label: _rangeLabel(today.subtract(const Duration(days: 6)), today),
        start: today.subtract(const Duration(days: 6)),
        end: today,
      ),
      DriverEarningsPeriod.thirtyDays => DriverEarningsExportPeriod(
        label: _rangeLabel(today.subtract(const Duration(days: 29)), today),
        start: today.subtract(const Duration(days: 29)),
        end: today,
      ),
    };
  }

  DateTime _startOfDay(DateTime date) {
    final local = date.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  String _singleDayLabel(String prefix, DateTime date) {
    return '$prefix - ${DateFormat('dd MMM yyyy', 'fr_FR').format(date)}';
  }

  String _rangeLabel(DateTime start, DateTime end) {
    final formatter = DateFormat('dd MMM yyyy', 'fr_FR');
    return 'Du ${formatter.format(start)} au ${formatter.format(end)}';
  }
}

class _EarningsExportConfirmationDialog extends StatelessWidget {
  const _EarningsExportConfirmationDialog({
    required this.period,
    required this.summary,
  });

  final DriverEarningsExportPeriod period;
  final DriverEarningsSummary summary;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Exporter les recettes'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ExportSummaryLine(label: 'Période', value: period.label),
            _ExportSummaryLine(
              label: 'Courses terminées',
              value: summary.completedRideCount.toString(),
            ),
            _ExportSummaryLine(
              label: 'Total brut',
              value: summary.totalEarnings.toCFA,
            ),
            _ExportSummaryLine(
              label: 'Commission Fraya',
              value: summary.totalCommission.toCFA,
            ),
            _ExportSummaryLine(
              label: 'Gain net',
              value: summary.totalNetEarnings.toCFA,
            ),
            _ExportSummaryLine(
              label: 'Temps total en course',
              value: '${summary.totalTripMinutes} min',
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              DriverEarningsExportService.disclaimer,
              style: AppTextStyles.small.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Exporter'),
        ),
      ],
    );
  }
}

class _ExportSummaryLine extends StatelessWidget {
  const _ExportSummaryLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.small.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.small.copyWith(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodTabs extends StatelessWidget {
  const _PeriodTabs({required this.selectedPeriod, required this.onSelected});

  final DriverEarningsPeriod selectedPeriod;
  final ValueChanged<DriverEarningsPeriod> onSelected;

  @override
  Widget build(BuildContext context) {
    const labels = <DriverEarningsPeriod, String>{
      DriverEarningsPeriod.today: 'Aujourd\'hui',
      DriverEarningsPeriod.sevenDays: 'Semaine',
      DriverEarningsPeriod.thirtyDays: 'Mois',
    };

    return Row(
      children: DriverEarningsPeriod.values.map((period) {
        final isSelected = selectedPeriod == period;
        final isLast = period == DriverEarningsPeriod.thirtyDays;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : AppTheme.spacingSm),
            child: GestureDetector(
              onTap: () => onSelected(period),
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
                  color: isSelected
                      ? null
                      : context.colors.surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isSelected ? AppColors.shadowYellowSm : null,
                ),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      labels[period]!,
                      style: AppTextStyles.buttonSmall.copyWith(
                        color: context.colors.textPrimary,
                      ),
                      maxLines: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _EarningsSubFilterBar extends StatelessWidget {
  const _EarningsSubFilterBar({required this.filter, required this.controller});

  final DriverEarningsFilterState filter;
  final DriverEarningsFilterController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Filtrer par date', style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              label: const Text('30 jours'),
              selected: filter.customRange == null,
              onSelected: (_) => controller.clearCustomRange(),
              labelStyle: AppTextStyles.small.copyWith(
                color: filter.customRange == null
                    ? context.colors.textPrimary
                    : context.colors.textSecondary,
              ),
              selectedColor: AppColors.primaryLight,
              checkmarkColor: context.colors.textPrimary,
              side: BorderSide(color: context.colors.greyLight),
            ),
            OutlinedButton.icon(
              onPressed: () => _pickRange(context),
              icon: const Icon(Icons.date_range_outlined, size: 18),
              label: const Text('Période'),
            ),
          ],
        ),
        if (filter.customRange != null) ...[
          const SizedBox(height: 12),
          InputChip(
            label: Text(_formatRange(filter.customRange!)),
            deleteIcon: const Icon(Icons.close, size: 18),
            onDeleted: controller.clearCustomRange,
          ),
        ],
      ],
    );
  }

  Future<void> _pickRange(BuildContext context) async {
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

  String _formatRange(DateTimeRange range) {
    final formatter = DateFormat('dd MMM', 'fr_FR');
    return '${formatter.format(range.start)} - ${formatter.format(range.end)}';
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface,
        shape: BoxShape.circle,
        boxShadow: isDark ? null : AppColors.shadowMd,
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: context.colors.textPrimary,
        ),
        onPressed: onPressed,
      ),
    );
  }
}
