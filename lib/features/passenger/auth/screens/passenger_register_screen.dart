import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../shared/models/auth_state.dart';
import '../../../../shared/providers/auth_register_flow_controller.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/auth_sectioned_register_layout.dart';
import '../providers/passenger_auth_provider.dart';
import '../providers/passenger_register_flow_provider.dart';

class PassengerRegisterScreen extends ConsumerStatefulWidget {
  const PassengerRegisterScreen({super.key});

  @override
  ConsumerState<PassengerRegisterScreen> createState() =>
      _PassengerRegisterScreenState();
}

class _PassengerRegisterScreenState
    extends ConsumerState<PassengerRegisterScreen> {
  final _firstNamesController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSyncingFlowState = false;

  @override
  void initState() {
    super.initState();
    for (final controller in _draftControllers) {
      controller.addListener(_pushDraftFields);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_restoreDraft());
    });
  }

  @override
  void dispose() {
    for (final controller in _draftControllers) {
      controller.removeListener(_pushDraftFields);
      controller.dispose();
    }
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  List<TextEditingController> get _draftControllers => [
    _firstNamesController,
    _lastNameController,
    _emailController,
    _phoneController,
  ];

  Future<void> _restoreDraft() async {
    await ref.read(passengerRegisterFlowProvider.notifier).restoreDraft();
    if (!mounted) return;
    _syncControllers(ref.read(passengerRegisterFlowProvider));
  }

  Future<void> _sendOtp() async {
    _pushDraftFields();
    await ref.read(passengerRegisterFlowProvider.notifier).sendOtp();
  }

  Future<void> _resendOtp() async {
    _pushDraftFields();
    await ref.read(passengerRegisterFlowProvider.notifier).resendOtp();
  }

  Future<void> _verifyOtp() async {
    _pushDraftFields();
    await ref
        .read(passengerRegisterFlowProvider.notifier)
        .verifyOtp(_otpController.text);
  }

  Future<void> _completeRegistration() async {
    _pushDraftFields();
    await ref
        .read(passengerRegisterFlowProvider.notifier)
        .completeRegistration(password: _passwordController.text);
  }

  void _goBackStep() {
    ref.read(passengerRegisterFlowProvider.notifier).goBackStep();
  }

  void _pushDraftFields({String? genre}) {
    if (_isSyncingFlowState) return;
    ref
        .read(passengerRegisterFlowProvider.notifier)
        .updateDraftFields(
          phoneNumber: _phoneController.text,
          email: _emailController.text,
          firstNames: _firstNamesController.text,
          lastName: _lastNameController.text,
          genre: genre ?? ref.read(passengerRegisterFlowProvider).genre,
        );
  }

  void _syncControllers(AuthRegisterFlowState flow) {
    _isSyncingFlowState = true;
    try {
      _setText(_phoneController, flow.phoneNumber);
      _setText(_emailController, flow.email);
      _setText(_firstNamesController, flow.firstNames);
      _setText(_lastNameController, flow.lastName);
    } finally {
      _isSyncingFlowState = false;
    }
  }

  void _clearSensitiveControllers() {
    _otpController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(passengerAuthProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        context.goNamed(RouteNames.passengerHome);
      } else if (next.status == AuthStatus.error) {
        AppSnackBar.showError(
          context,
          next.errorMessage ?? "Erreur lors de l'inscription",
        );
      }
    });
    ref.listen<AuthRegisterFlowState>(passengerRegisterFlowProvider, (
      previous,
      next,
    ) {
      _syncControllers(next);
      if (_shouldClearSensitiveControllers(previous, next)) {
        _clearSensitiveControllers();
      }
    });

    final authState = ref.watch(passengerAuthProvider);
    final flowState = ref.watch(passengerRegisterFlowProvider);
    return AuthSectionedRegisterLayout(
      subtitle: 'Rejoignez Fraya Taxi et voyagez en toute simplicité',
      currentStep: flowState.currentStep,
      phoneController: _phoneController,
      emailController: _emailController,
      otpController: _otpController,
      firstNamesController: _firstNamesController,
      lastNameController: _lastNameController,
      passwordController: _passwordController,
      confirmPasswordController: _confirmPasswordController,
      selectedGenre: flowState.genre,
      onGenreChanged: (value) => _pushDraftFields(genre: value),
      onSendOtp: _sendOtp,
      onVerifyOtp: _verifyOtp,
      onResendOtp: _resendOtp,
      onCompleteRegistration: _completeRegistration,
      onBack: _goBackStep,
      onLogin: () => context.goNamed(RouteNames.login),
      isLoading: authState.status == AuthStatus.loading,
      isResendingOtp: flowState.isResendingOtp,
      otpResendSecondsRemaining: flowState.otpResendSecondsRemaining,
    );
  }
}

bool _shouldClearSensitiveControllers(
  AuthRegisterFlowState? previous,
  AuthRegisterFlowState next,
) {
  return previous != null &&
      !_isEmptyFlowState(previous) &&
      _isEmptyFlowState(next);
}

bool _isEmptyFlowState(AuthRegisterFlowState state) {
  return state.currentStep.name == 'contact' &&
      state.phoneNumber == null &&
      state.email == null &&
      state.firstNames == null &&
      state.lastName == null &&
      state.genre == null &&
      state.otpResendSecondsRemaining == 0 &&
      !state.isResendingOtp;
}

void _setText(TextEditingController controller, String? value) {
  final next = value ?? '';
  if (controller.text != next) {
    controller.text = next;
  }
}
