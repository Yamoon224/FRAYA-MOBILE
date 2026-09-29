import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/settings/account_notification_preferences_card.dart';
import '../../../../shared/widgets/settings/account_notifications_screen.dart';
import '../providers/driver_notifications_provider.dart';
import '../providers/driver_settings_provider.dart';

class DriverNotificationsScreen extends ConsumerWidget {
  const DriverNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncNotifications = ref.watch(driverNotificationsProvider);
    final isSubmitting = ref.watch(driverNotificationsControllerProvider);
    final settings = ref.watch(driverSettingsProvider);

    return AccountNotificationsScreen(
      asyncNotifications: asyncNotifications,
      isSubmitting: isSubmitting,
      header: AccountNotificationPreferencesCard(
        notificationsEnabled: settings.notificationsEnabled,
        soundsEnabled: settings.soundsEnabled,
        onToggleNotifications: () =>
            ref.read(driverSettingsProvider.notifier).toggleNotifications(),
        onToggleSounds: () =>
            ref.read(driverSettingsProvider.notifier).toggleSounds(),
      ),
      onRefresh: () async {
        ref.invalidate(driverNotificationsProvider);
        await ref.read(driverNotificationsProvider.future);
      },
      onMarkAsRead: (ids) async {
        await ref
            .read(driverNotificationsControllerProvider.notifier)
            .markAsRead(ids);
      },
    );
  }
}
