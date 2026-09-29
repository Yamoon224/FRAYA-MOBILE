import 'package:flutter_riverpod/legacy.dart';

import '../../../../domain/models/auth_register_draft.dart';
import '../../../../shared/models/auth_state.dart';
import '../../../../shared/providers/auth_register_draft_provider.dart';
import '../../../../shared/providers/auth_register_flow_controller.dart';
import 'passenger_auth_provider.dart';

final passengerRegisterFlowProvider =
    StateNotifierProvider.autoDispose<
      AuthRegisterFlowController,
      AuthRegisterFlowState
    >((ref) {
      final authNotifier = ref.watch(passengerAuthProvider.notifier);
      return AuthRegisterFlowController(
        role: AuthRegisterRole.passenger,
        userRegistrationType: 'USER',
        draftRepository: ref.watch(authRegisterDraftRepositoryProvider),
        sendOtpAction: authNotifier.registerStep1,
        verifyOtpAction: authNotifier.registerStep2,
        completeRegistrationAction: authNotifier.registerStep3,
        isAuthenticated: () =>
            ref.read(passengerAuthProvider).status == AuthStatus.authenticated,
      );
    });
