library;

import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../../core/services/support_whatsapp_launcher_service.dart';
import '../usecase.dart';

class OpenSupportWhatsAppParams {
  const OpenSupportWhatsAppParams({
    required this.phoneNumber,
    required this.message,
  });

  final String phoneNumber;
  final String message;
}

class OpenSupportWhatsAppUseCase
    extends UseCase<bool, OpenSupportWhatsAppParams> {
  OpenSupportWhatsAppUseCase(this._service);

  final SupportWhatsAppLauncherService _service;

  @override
  Future<Either<Failure, bool>> call(OpenSupportWhatsAppParams params) async {
    try {
      final opened = await _service.openSupportChat(
        rawPhoneNumber: params.phoneNumber,
        message: params.message,
      );
      if (!opened) {
        return left(
          const ServerFailure(
            message: 'Impossible d\'ouvrir WhatsApp sur cet appareil.',
          ),
        );
      }
      return right(true);
    } catch (error) {
      return left(
        ServerFailure(message: 'Impossible d\'ouvrir WhatsApp : $error'),
      );
    }
  }
}
