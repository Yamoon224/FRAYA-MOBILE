import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:fraya_mobile/core/models/ride_model.dart';
import 'package:fraya_mobile/core/theme/app_colors.dart';
import 'package:fraya_mobile/core/theme/app_text_styles.dart';
import 'package:fraya_mobile/core/theme/app_theme.dart';
import 'package:fraya_mobile/core/utils/extensions.dart';
import 'package:fraya_mobile/core/utils/responsive.dart';

class RideSummaryCard extends StatelessWidget {
  const RideSummaryCard({super.key, required this.ride});

  final Ride ride;

  static String _formatDate(DateTime d) {
    final raw = DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(d.toLocal());
    return raw[0].toUpperCase() + raw.substring(1);
  }

  static String _formatTime(DateTime? d) {
    if (d == null) return '--:--';
    return DateFormat('HH:mm', 'fr_FR').format(d.toLocal());
  }

  static String _formatDuration(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '-- min';
    final trimmed = raw.trim();
    return (trimmed.contains('min') || trimmed.contains('h'))
        ? trimmed
        : '$trimmed min';
  }

  static String _formatDistance(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '-- km';
    final trimmed = raw.trim();
    return trimmed.contains('km') ? trimmed : '$trimmed km';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(
        context.responsiveValue<double>(
          compact: AppTheme.spacingMd,
          phone: AppTheme.spacingLg,
          largePhone: AppTheme.spacingLg,
          tablet: 28,
        ),
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius2xl),
        boxShadow: AppColors.shadowSm,
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Date de la course',
            value: _formatDate(ride.date),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final start = _InfoRow(
                icon: Icons.play_circle_outline,
                label: 'Début',
                value: _formatTime(ride.startedAt),
              );
              final end = _InfoRow(
                icon: Icons.stop_circle_outlined,
                label: 'Fin',
                value: _formatTime(ride.endedAt ?? ride.completedAt),
                crossAxisAlignment: CrossAxisAlignment.end,
              );

              if (constraints.maxWidth < 260) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [start, const SizedBox(height: 12), end],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: start),
                  const SizedBox(width: 16),
                  Expanded(child: end),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final duration = _StatBox(
                label: 'Durée',
                value: _formatDuration(ride.duration),
              );
              final distance = _StatBox(
                label: 'Distance',
                value: _formatDistance(ride.distance),
              );

              if (constraints.maxWidth < 260) {
                return Column(
                  children: [duration, const SizedBox(height: 12), distance],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: duration),
                  const SizedBox(width: 12),
                  Expanded(child: distance),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final IconData icon;
  final String label;
  final String value;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.xs.copyWith(color: context.colors.textTertiary),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.primaryLight),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: context.responsiveValue<double>(
          compact: 10,
          phone: 12,
          largePhone: 12,
          tablet: 14,
        ),
        horizontal: context.responsiveValue<double>(
          compact: 12,
          phone: 16,
          largePhone: 16,
          tablet: 18,
        ),
      ),
      decoration: BoxDecoration(
        color: context.colors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.xs.copyWith(color: context.colors.textTertiary),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
