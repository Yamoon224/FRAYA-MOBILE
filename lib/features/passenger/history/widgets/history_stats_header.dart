import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/measurement_formatter.dart';
import '../providers/history_provider.dart';

class HistoryStatsHeader extends ConsumerWidget {
  const HistoryStatsHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(historyStatsProvider);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 14),
      color: context.colors.surface,
      child: statsAsync.when(
        data: (stats) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(value: stats['totalRides'].toString(), label: 'Courses'),
            _StatItem(
              value: MeasurementFormatter.formatCurrency(stats['totalSpent']),
              label: 'Dépenses',
            ),
            _StatItem(
              value: stats['avgRating'].toStringAsFixed(1),
              label: 'Note moyenne',
              isRating: true,
            ),
          ],
        ),
        loading: () => const SizedBox(
          height: 30,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (error, stack) => const SizedBox.shrink(),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final bool isRating;

  const _StatItem({
    required this.value,
    required this.label,
    this.isRating = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isRating) ...[
              const Icon(Icons.star, color: AppColors.primary, size: 20),
              const SizedBox(width: 4),
            ],
            Text(
              value,
              style: AppTextStyles.h1.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.xs.copyWith(color: context.colors.textSecondary),
        ),
      ],
    );
  }
}
