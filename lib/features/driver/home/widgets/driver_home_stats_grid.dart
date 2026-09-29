library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/responsive.dart';

class DriverHomeStatsGrid extends StatelessWidget {
  const DriverHomeStatsGrid({
    super.key,
    required this.earnings,
    required this.walletBalance,
    required this.rideCount,
    required this.onlineHours,
  });

  final double earnings;
  final double walletBalance;
  final int rideCount;
  final double? onlineHours;

  @override
  Widget build(BuildContext context) {
    final shouldStack = MediaQuery.sizeOf(context).width < 330;

    return Column(
      children: [
        if (shouldStack)
          Column(
            children: [
              _HighlightStatCard(
                label: 'Recette',
                value: earnings.toCFA,
                icon: Icons.attach_money_rounded,
              ),
              const SizedBox(height: AppTheme.spacingSm),
              _CompactStatCard(
                label: 'Mon solde',
                value: walletBalance.toCFA,
                icon: Icons.account_balance_wallet_outlined,
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: _HighlightStatCard(
                  label: 'Recette',
                  value: earnings.toCFA,
                  icon: Icons.attach_money_rounded,
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: _CompactStatCard(
                  label: 'Mon solde',
                  value: walletBalance.toCFA,
                  icon: Icons.account_balance_wallet_outlined,
                ),
              ),
            ],
          ),
        const SizedBox(height: AppTheme.spacingSm),
        if (shouldStack)
          Column(
            children: [
              _CompactStatCard(
                label: 'Courses',
                value: '$rideCount',
                icon: Icons.near_me_outlined,
              ),
              const SizedBox(height: AppTheme.spacingSm),
              _CompactStatCard(
                label: 'Temps',
                value: _formatHours(onlineHours),
                icon: Icons.access_time_rounded,
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: _CompactStatCard(
                  label: 'Courses',
                  value: '$rideCount',
                  icon: Icons.near_me_outlined,
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: _CompactStatCard(
                  label: 'Temps',
                  value: _formatHours(onlineHours),
                  icon: Icons.access_time_rounded,
                ),
              ),
            ],
          ),
      ],
    );
  }

  String _formatHours(double? hours) {
    if (hours == null || hours <= 0) {
      return '0h';
    }
    final totalMinutes = (hours * 60).round();
    final formattedHours = totalMinutes ~/ 60;
    final formattedMinutes = totalMinutes % 60;
    if (formattedMinutes == 0) {
      return '${formattedHours}h';
    }
    return '${formattedHours}h ${formattedMinutes}min';
  }
}

class _HighlightStatCard extends StatelessWidget {
  const _HighlightStatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final padding = EdgeInsets.fromLTRB(
      context.responsiveValue<double>(
        compact: 18,
        phone: 20,
        largePhone: 24,
        tablet: 28,
      ),
      context.responsiveValue<double>(
        compact: 16,
        phone: 18,
        largePhone: 20,
        tablet: 22,
      ),
      context.responsiveValue<double>(
        compact: 18,
        phone: 20,
        largePhone: 24,
        tablet: 28,
      ),
      context.responsiveValue<double>(
        compact: 16,
        phone: 18,
        largePhone: 20,
        tablet: 22,
      ),
    );
    final valueStyle = AppTextStyles.h1.copyWith(
      color: context.colors.isDark ? const Color(0xFFE8E8E8) : const Color(0xFF161616),
      fontSize: context.responsiveValue<double>(
        compact: 18,
        phone: 20,
        largePhone: 22,
        tablet: 24,
      ),
      height: 1.2,
    );

    return Container(
      constraints: BoxConstraints(
        minHeight: context.responsiveValue<double>(
          compact: 118,
          phone: 124,
          largePhone: 132,
          tablet: 140,
        ),
      ),
      padding: padding,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFD3A235),
            Color(0xFFF5E7AA),
            Color(0xFFD09A28),
          ],
        ),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFF2D888), width: 0.8),
        boxShadow: AppColors.shadowYellowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: context.colors.textPrimary),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textBody.copyWith(
                    color: context.colors.isDark ? const Color(0xFFD0D0D0) : const Color(0xFF2C2C2C),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: valueStyle,
          ),
        ],
      ),
    );
  }
}

class _CompactStatCard extends StatelessWidget {
  const _CompactStatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final padding = EdgeInsets.fromLTRB(
      context.responsiveValue<double>(
        compact: 18,
        phone: 20,
        largePhone: 24,
        tablet: 28,
      ),
      context.responsiveValue<double>(
        compact: 16,
        phone: 18,
        largePhone: 20,
        tablet: 22,
      ),
      context.responsiveValue<double>(
        compact: 18,
        phone: 20,
        largePhone: 24,
        tablet: 28,
      ),
      context.responsiveValue<double>(
        compact: 16,
        phone: 18,
        largePhone: 20,
        tablet: 22,
      ),
    );
    final valueStyle = AppTextStyles.h1.copyWith(
      color: context.colors.textPrimary,
      fontSize: context.responsiveValue<double>(
        compact: 18,
        phone: 20,
        largePhone: 22,
        tablet: 24,
      ),
      height: 1.2,
    );

    return Container(
      constraints: BoxConstraints(
        minHeight: context.responsiveValue<double>(
          compact: 118,
          phone: 124,
          largePhone: 132,
          tablet: 140,
        ),
      ),
      padding: padding,
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: context.colors.border),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primaryDark),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textSmall.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: valueStyle,
          ),
        ],
      ),
    );
  }
}
