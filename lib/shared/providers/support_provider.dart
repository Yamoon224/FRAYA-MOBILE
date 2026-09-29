library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/services/support_whatsapp_launcher_service.dart';
import '../../domain/usecases/shared/open_support_whatsapp.dart';
import '../models/support_topic.dart';

class SupportController {
  const SupportController(this._openSupportWhatsAppUseCase);

  final OpenSupportWhatsAppUseCase _openSupportWhatsAppUseCase;

  String buildMessage({
    required SupportAudience audience,
    required SupportTopic topic,
  }) {
    return [
      'Bonjour equipe support Fraya,',
      '',
      'Je vous contacte pour le motif suivant : ${topic.label}.',
      'Application : ${audience.appLabel}',
      'Profil : ${audience.roleLabel}',
    ].join('\n');
  }

  Future<String?> openTopic({
    required SupportAudience audience,
    required SupportTopic topic,
  }) async {
    final supportNumber = AppConfig.instance.supportWhatsAppNumber.trim();
    if (supportNumber.isEmpty) {
      return 'Le numero WhatsApp du support n\'est pas encore configure.';
    }

    final result = await _openSupportWhatsAppUseCase(
      OpenSupportWhatsAppParams(
        phoneNumber: supportNumber,
        message: buildMessage(audience: audience, topic: topic),
      ),
    );
    return result.fold((failure) => failure.message, (_) => null);
  }
}

final supportWhatsAppLauncherServiceProvider =
    Provider<SupportWhatsAppLauncherService>((ref) {
      return SupportWhatsAppLauncherService();
    });

final openSupportWhatsAppUseCaseProvider = Provider<OpenSupportWhatsAppUseCase>(
  (ref) {
    final service = ref.watch(supportWhatsAppLauncherServiceProvider);
    return OpenSupportWhatsAppUseCase(service);
  },
);

final supportControllerProvider = Provider<SupportController>((ref) {
  final useCase = ref.watch(openSupportWhatsAppUseCaseProvider);
  return SupportController(useCase);
});

final supportTopicsProvider =
    Provider.family<List<SupportTopic>, SupportAudience>(
      (ref, audience) => SupportTopics.forAudience(audience),
    );
