library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/app_alert_service.dart';

final appAlertServiceProvider = Provider<AppAlertService>((ref) {
  return AppAlertService.instance;
});
