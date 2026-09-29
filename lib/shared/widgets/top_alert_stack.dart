library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../models/top_alert_item.dart';
import '../providers/top_alerts_provider.dart';

class TopAlertsStack extends ConsumerWidget {
  const TopAlertsStack({
    super.key,
    this.source,
  });

  final TopAlertSource? source;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(topAlertsProvider);
    final filteredAlerts = source == null
        ? alerts
        : alerts.where((alert) => alert.source == source).toList(growable: false);

    if (filteredAlerts.isEmpty) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final alert in filteredAlerts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _TopAlertCard(alert: alert),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopAlertCard extends ConsumerWidget {
  const _TopAlertCard({required this.alert});

  final TopAlertItem alert;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onVerticalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity < -250) {
          ref.read(topAlertsProvider.notifier).dismiss(alert.id);
        }
      },
      child: Dismissible(
        key: ValueKey<String>(alert.id),
        direction: DismissDirection.horizontal,
        onDismissed: (_) => ref.read(topAlertsProvider.notifier).dismiss(alert.id),
        child: Material(
          color: _backgroundColor(alert.severity),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(_iconFor(alert.severity), color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        alert.title,
                        style: AppTextStyles.body.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        alert.message,
                        style: AppTextStyles.small.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static IconData _iconFor(TopAlertSeverity severity) {
    switch (severity) {
      case TopAlertSeverity.error:
        return Icons.error_outline_rounded;
      case TopAlertSeverity.warning:
        return Icons.warning_amber_rounded;
      case TopAlertSeverity.info:
        return Icons.info_outline_rounded;
      case TopAlertSeverity.success:
        return Icons.check_circle_outline_rounded;
    }
  }

  static Color _backgroundColor(TopAlertSeverity severity) {
    switch (severity) {
      case TopAlertSeverity.error:
        return AppColors.error;
      case TopAlertSeverity.warning:
        return const Color(0xFFB45309);
      case TopAlertSeverity.info:
        return AppColors.info;
      case TopAlertSeverity.success:
        return AppColors.success;
    }
  }
}
