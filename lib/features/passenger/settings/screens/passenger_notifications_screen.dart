import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/settings/account_notification_preferences_card.dart';
import '../../../../shared/widgets/settings/account_notifications_screen.dart';
import '../providers/passenger_notifications_provider.dart';
import '../providers/passenger_settings_provider.dart';

class PassengerNotificationsScreen extends ConsumerWidget {
  const PassengerNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncNotifications = ref.watch(passengerNotificationsProvider);
    final isSubmitting = ref.watch(passengerNotificationsControllerProvider);
    final settings = ref.watch(passengerSettingsProvider);

    return AccountNotificationsScreen(
      asyncNotifications: asyncNotifications,
      isSubmitting: isSubmitting,
      header: AccountNotificationPreferencesCard(
        notificationsEnabled: settings.notificationsEnabled,
        soundsEnabled: settings.soundsEnabled,
        onToggleNotifications: () =>
            ref.read(passengerSettingsProvider.notifier).toggleNotifications(),
        onToggleSounds: () =>
            ref.read(passengerSettingsProvider.notifier).toggleSounds(),
      ),
      onRefresh: () async {
        ref.invalidate(passengerNotificationsProvider);
        await ref.read(passengerNotificationsProvider.future);
      },
      onMarkAsRead: (ids) async {
        await ref
            .read(passengerNotificationsControllerProvider.notifier)
            .markAsRead(ids);
      },
    );
  }
}
