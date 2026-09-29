import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/extensions.dart';

class AccountNotificationPreferencesCard extends StatelessWidget {
  const AccountNotificationPreferencesCard({
    super.key,
    required this.notificationsEnabled,
    required this.soundsEnabled,
    required this.onToggleNotifications,
    required this.onToggleSounds,
  });

  final bool notificationsEnabled;
  final bool soundsEnabled;
  final VoidCallback onToggleNotifications;
  final VoidCallback onToggleSounds;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(
        children: [
          _PreferenceTile(
            icon: Icons.notifications_active_outlined,
            title: 'Notifications in-app',
            subtitle: 'Affiche les alertes pendant l utilisation de l app.',
            value: notificationsEnabled,
            onChanged: (_) => onToggleNotifications(),
          ),
          Divider(
            height: 1,
            color: context.colors.isDark
                ? context.colors.border
                : context.colors.greyExtraLight.withValues(alpha: .8),
          ),
          _PreferenceTile(
            icon: Icons.volume_up_outlined,
            title: 'Sons',
            subtitle: 'Joue le son des alertes quand elles apparaissent.',
            value: soundsEnabled,
            onChanged: notificationsEnabled ? (_) => onToggleSounds() : null,
          ),
        ],
      ),
    );
  }
}

class _PreferenceTile extends StatelessWidget {
  const _PreferenceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      value: value,
      onChanged: onChanged,
      secondary: Icon(icon, color: AppColors.primary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      title: Text(
        title,
        style: AppTextStyles.body.copyWith(
          color: context.colors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.small.copyWith(color: context.colors.textSecondary),
      ),
    );
  }
}
