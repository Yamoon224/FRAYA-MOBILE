import 'package:flutter_riverpod/legacy.dart';

import '../../../../domain/models/auth_register_draft.dart';
import '../../../../shared/models/auth_state.dart';
import '../../../../shared/providers/auth_register_draft_provider.dart';
import '../../../../shared/providers/auth_register_flow_controller.dart';
import 'driver_auth_provider.dart';

final driverRegisterFlowProvider =
    StateNotifierProvider.autoDispose<
      AuthRegisterFlowController,
      AuthRegisterFlowState
    >((ref) {
      final authNotifier = ref.watch(driverAuthProvider.notifier);
      return AuthRegisterFlowController(
        role: AuthRegisterRole.driver,
        userRegistrationType: 'DRIVER',
        draftRepository: ref.watch(authRegisterDraftRepositoryProvider),
        sendOtpAction: authNotifier.registerStep1,
        verifyOtpAction: authNotifier.registerStep2,
        completeRegistrationAction: authNotifier.register,
        isAuthenticated: () =>
            ref.read(driverAuthProvider).status == AuthStatus.authenticated,
      );
    });
