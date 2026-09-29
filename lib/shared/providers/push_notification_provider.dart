library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/push_notification_service.dart';

final pushNotificationServiceProvider = Provider<PushNotificationService>((
  ref,
) {
  return PushNotificationService.instance;
});

final pushNotificationTapStreamProvider =
    Provider<Stream<PushNotificationPayload>>((ref) {
      return ref.watch(pushNotificationServiceProvider).onNotificationTap;
    });

final pushNotificationReceivedStreamProvider =
    Provider<Stream<PushNotificationPayload>>((ref) {
      return ref.watch(pushNotificationServiceProvider).onNotificationReceived;
    });
