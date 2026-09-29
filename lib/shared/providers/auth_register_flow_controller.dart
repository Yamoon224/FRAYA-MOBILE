import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';

import '../../domain/models/auth_register_draft.dart';
import '../../domain/repositories/auth_register_draft_repository.dart';

typedef AuthRegisterStep1Action = Future<void> Function(String phoneNumber, {String? email});
typedef AuthRegisterStep2Action =
    Future<void> Function(String phoneNumber, String verificationCode);
typedef AuthRegisterCompleteAction =
    Future<void> Function(Map<String, dynamic> payload);
typedef AuthRegisterSuccessReader = bool Function();
class AuthRegisterFlowState {
  const AuthRegisterFlowState({
    this.currentStep = AuthRegisterFlowStep.contact,
    this.phoneNumber,
    this.email,
    this.firstNames,
    this.lastName,
    this.genre,
    this.dateOfBirth,
    this.otpResendSecondsRemaining = 0,
    this.isResendingOtp = false,
    this.isRestoringDraft = false,
  });

  final AuthRegisterFlowStep currentStep;
  final String? phoneNumber;
  final String? email;
  final String? firstNames;
  final String? lastName;
  final String? genre;
  final String? dateOfBirth;
  final int otpResendSecondsRemaining;
  final bool isResendingOtp;
  final bool isRestoringDraft;

  AuthRegisterFlowState copyWith({
    AuthRegisterFlowStep? currentStep,
    Object? phoneNumber = _sentinel,
    Object? email = _sentinel,
    Object? firstNames = _sentinel,
    Object? lastName = _sentinel,
    Object? genre = _sentinel,
    Object? dateOfBirth = _sentinel,
    int? otpResendSecondsRemaining,
    bool? isResendingOtp,
    bool? isRestoringDraft,
  }) {
    return AuthRegisterFlowState(
      currentStep: currentStep ?? this.currentStep,
      phoneNumber: identical(phoneNumber, _sentinel)
          ? this.phoneNumber
          : phoneNumber as String?,
      email: identical(email, _sentinel) ? this.email : email as String?,
      firstNames: identical(firstNames, _sentinel)
          ? this.firstNames
          : firstNames as String?,
      lastName: identical(lastName, _sentinel)
          ? this.lastName
          : lastName as String?,
      genre: identical(genre, _sentinel) ? this.genre : genre as String?,
      dateOfBirth: identical(dateOfBirth, _sentinel)
          ? this.dateOfBirth
          : dateOfBirth as String?,
      otpResendSecondsRemaining:
          otpResendSecondsRemaining ?? this.otpResendSecondsRemaining,
      isResendingOtp: isResendingOtp ?? this.isResendingOtp,
      isRestoringDraft: isRestoringDraft ?? this.isRestoringDraft,
    );
  }
}

class AuthRegisterFlowController extends StateNotifier<AuthRegisterFlowState> {
  AuthRegisterFlowController({
    required AuthRegisterRole role,
    required String userRegistrationType,
    required AuthRegisterDraftRepository draftRepository,
    required AuthRegisterStep1Action sendOtpAction,
    required AuthRegisterStep2Action verifyOtpAction,
    required AuthRegisterCompleteAction completeRegistrationAction,
    required AuthRegisterSuccessReader isAuthenticated,
  }) : _role = role,
       _userRegistrationType = userRegistrationType,
       _draftRepository = draftRepository,
       _sendOtpAction = sendOtpAction,
       _verifyOtpAction = verifyOtpAction,
       _completeRegistrationAction = completeRegistrationAction,
       _isAuthenticated = isAuthenticated,
       super(const AuthRegisterFlowState());

  final AuthRegisterRole _role;
  final String _userRegistrationType;
  final AuthRegisterDraftRepository _draftRepository;
  final AuthRegisterStep1Action _sendOtpAction;
  final AuthRegisterStep2Action _verifyOtpAction;
  final AuthRegisterCompleteAction _completeRegistrationAction;
  final AuthRegisterSuccessReader _isAuthenticated;
  Timer? _draftDebounce;
  Timer? _otpCooldownTimer;

  Future<void> restoreDraft() async {
    state = state.copyWith(isRestoringDraft: true);
    final draft = await _draftRepository.readDraft(_role);
    if (draft == null) {
      state = state.copyWith(isRestoringDraft: false);
      return;
    }
    state = state.copyWith(
      currentStep: _canRestoreStep(draft)
          ? draft.step
          : AuthRegisterFlowStep.contact,
      phoneNumber: draft.phoneNumber,
      email: draft.email,
      firstNames: draft.firstNames,
      lastName: draft.lastName,
      genre: draft.genre,
      dateOfBirth: draft.dateOfBirth,
      isRestoringDraft: false,
    );
  }

  void updateDraftFields({
    required String phoneNumber,
    required String email,
    required String firstNames,
    required String lastName,
    required String? genre,
    String? dateOfBirth,
  }) {
    state = state.copyWith(
      phoneNumber: _optionalText(phoneNumber),
      email: _optionalText(email),
      firstNames: _optionalText(firstNames, true),
      lastName: _optionalText(lastName, true),
      genre: _optionalText(genre),
      dateOfBirth: _optionalText(dateOfBirth),
    );
    _scheduleDraftSave();
  }

  Future<void> sendOtp() async {
    await _saveDraft(step: AuthRegisterFlowStep.contact);
    try {
      await _sendOtpAction(_phoneNumber, email: state.email);
    } catch (_) {
      return;
    }
    state = state.copyWith(currentStep: AuthRegisterFlowStep.otp);
    _startOtpCooldown();
    await _saveDraft(step: AuthRegisterFlowStep.otp);
  }

  Future<void> resendOtp() async {
    if (state.otpResendSecondsRemaining > 0 || state.isResendingOtp) return;
    state = state.copyWith(isResendingOtp: true);
    try {
      await _sendOtpAction(_phoneNumber, email: state.email);
      _startOtpCooldown();
      await _saveDraft(step: AuthRegisterFlowStep.otp);
    } catch (_) {
      // The auth provider exposes the error message to the screen listener.
    } finally {
      state = state.copyWith(isResendingOtp: false);
    }
  }

  Future<void> verifyOtp(String verificationCode) async {
    try {
      await _verifyOtpAction(_phoneNumber, verificationCode.trim());
    } catch (_) {
      return;
    }
    state = state.copyWith(currentStep: AuthRegisterFlowStep.details);
    await _saveDraft(step: AuthRegisterFlowStep.details);
  }

  Future<void> completeRegistration({required String password}) async {
    _cancelDraftDebounce();
    await _saveDraft(step: AuthRegisterFlowStep.details);
    await _completeRegistrationAction(_payload(password));
    if (_isAuthenticated()) {
      await _clearRegistrationDraftAndState();
    }
  }

  void goBackStep() {
    state = state.copyWith(
      currentStep: state.currentStep == AuthRegisterFlowStep.details
          ? AuthRegisterFlowStep.otp
          : AuthRegisterFlowStep.contact,
    );
    _scheduleDraftSave();
  }

  void _scheduleDraftSave() {
    if (state.isRestoringDraft) return;
    _cancelDraftDebounce();
    _draftDebounce = Timer(
      const Duration(milliseconds: 350),
      () => unawaited(_saveDraft()),
    );
  }

  Future<void> _saveDraft({AuthRegisterFlowStep? step}) {
    return _draftRepository.saveDraft(
      AuthRegisterDraft(
        role: _role,
        step: step ?? state.currentStep,
        phoneNumber: state.phoneNumber,
        email: state.email,
        firstNames: state.firstNames,
        lastName: state.lastName,
        genre: state.genre,
        dateOfBirth: state.dateOfBirth,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Map<String, dynamic> _payload(String password) {
    return {
      'firstNames': state.firstNames?.trim(),
      'lastName': state.lastName?.trim(),
      if (state.email != null) 'email': state.email,
      'phoneNumber': _phoneNumber,
      'password': password,
      'genre': state.genre,
      'userRegistrationType': _userRegistrationType,
      if (state.dateOfBirth != null)
        'dateOfBirth': _ddMmYyyyToIso(state.dateOfBirth!),
    };
  }

  static String _ddMmYyyyToIso(String ddMmYyyy) {
    final parts = ddMmYyyy.split('-');
    return '${parts[2]}-${parts[1]}-${parts[0]}';
  }

  String get _phoneNumber => state.phoneNumber?.trim() ?? '';

  void _startOtpCooldown() {
    _cancelOtpCooldown();
    state = state.copyWith(otpResendSecondsRemaining: 30);
    _otpCooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.otpResendSecondsRemaining <= 1) {
        timer.cancel();
        state = state.copyWith(otpResendSecondsRemaining: 0);
        return;
      }
      state = state.copyWith(
        otpResendSecondsRemaining: state.otpResendSecondsRemaining - 1,
      );
    });
  }

  Future<void> _clearRegistrationDraftAndState() async {
    _cancelDraftDebounce();
    _cancelOtpCooldown();
    await _draftRepository.clearDraft(_role);
    state = const AuthRegisterFlowState();
  }

  void _cancelDraftDebounce() {
    _draftDebounce?.cancel();
    _draftDebounce = null;
  }

  void _cancelOtpCooldown() {
    _otpCooldownTimer?.cancel();
    _otpCooldownTimer = null;
  }

  bool _canRestoreStep(AuthRegisterDraft draft) {
    return draft.step == AuthRegisterFlowStep.contact ||
        (draft.phoneNumber?.isNotEmpty ?? false);
  }

  @override
  void dispose() {
    _cancelDraftDebounce();
    _cancelOtpCooldown();
    super.dispose();
  }
}

String? _optionalText(String? value, [bool preserveSpaces = false]) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : preserveSpaces ? value : trimmed;
}
const Object _sentinel = Object();
