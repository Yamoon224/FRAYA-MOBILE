import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import 'app_snack_bar.dart';
import 'fraya_button.dart';
import 'fraya_text_field.dart';

Future<bool?> showAuthOtpDialog({
  required BuildContext context,
  required String title,
  required String description,
  required Future<void> Function(String otp) onSubmit,
  Future<void> Function()? onResend,
  String? successMessage,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _AuthOtpDialog(
      title: title,
      description: description,
      onSubmit: onSubmit,
      onResend: onResend,
      successMessage: successMessage,
    ),
  );
}

class _AuthOtpDialog extends StatefulWidget {
  const _AuthOtpDialog({
    required this.title,
    required this.description,
    required this.onSubmit,
    this.onResend,
    this.successMessage,
  });

  final String title;
  final String description;
  final Future<void> Function(String otp) onSubmit;
  final Future<void> Function()? onResend;
  final String? successMessage;

  @override
  State<_AuthOtpDialog> createState() => _AuthOtpDialogState();
}

class _AuthOtpDialogState extends State<_AuthOtpDialog> {
  static const int _resendCooldownSeconds = 30;

  final TextEditingController _otpController = TextEditingController();
  String? _errorText;
  bool _isSubmitting = false;
  bool _isResending = false;
  int _resendSecondsRemaining = 0;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    if (widget.onResend != null) {
      _startResendCooldown();
    }
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      setState(() {
        _errorText = 'Veuillez saisir le code OTP.';
      });
      return;
    }

    if (otp.length != 4) {
      setState(() {
        _errorText = 'Le code OTP doit contenir 4 chiffres.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      await widget.onSubmit(otp);
      if (!mounted) {
        return;
      }
      if (widget.successMessage != null) {
        AppSnackBar.showSuccess(context, widget.successMessage!);
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSubmitting = false;
        _errorText = _extractErrorMessage(error);
      });
    }
  }

  Future<void> _resend() async {
    if (!_canResend) return;

    setState(() {
      _isResending = true;
      _errorText = null;
    });

    try {
      await widget.onResend?.call();
      if (!mounted) return;
      setState(() {
        _isResending = false;
      });
      _startResendCooldown();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isResending = false;
        _errorText = _extractErrorMessage(error);
      });
    }
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() {
      _resendSecondsRemaining = _resendCooldownSeconds;
    });
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendSecondsRemaining <= 1) {
        timer.cancel();
        setState(() {
          _resendSecondsRemaining = 0;
        });
        return;
      }
      setState(() {
        _resendSecondsRemaining -= 1;
      });
    });
  }

  bool get _canResend =>
      widget.onResend != null &&
      _resendSecondsRemaining <= 0 &&
      !_isResending &&
      !_isSubmitting;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      title: Text(
        widget.title,
        style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.description,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            FrayaTextField(
              controller: _otpController,
              label: 'Code OTP',
              hint: '1234',
              prefixIcon: Icons.sms_outlined,
              autofocus: true,
              enabled: !_isSubmitting,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              onSubmitted: (_) {
                if (!_isSubmitting) {
                  _submit();
                }
              },
            ),
            if (_errorText != null) ...[
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                _errorText!,
                style: AppTextStyles.small.copyWith(color: AppColors.error),
              ),
            ],
            const SizedBox(height: AppTheme.spacingLg),
            FrayaButton(
              label: 'Valider',
              onPressed: _isSubmitting ? null : _submit,
              isLoading: _isSubmitting,
            ),
            if (widget.onResend != null) ...[
              const SizedBox(height: 12),
              FrayaButton(
                label: _resendSecondsRemaining > 0
                    ? 'Renvoyer dans ${_resendSecondsRemaining}s'
                    : "Renvoyer l'OTP",
                variant: FrayaButtonVariant.outline,
                leftIcon: Icons.refresh_rounded,
                onPressed: _canResend ? _resend : null,
                isLoading: _isResending,
              ),
            ],
            const SizedBox(height: 12),
            FrayaButton(
              label: 'Annuler',
              variant: FrayaButtonVariant.ghost,
              onPressed: _isSubmitting
                  ? null
                  : () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}

String _extractErrorMessage(Object error) {
  final text = error.toString().trim();
  if (text.startsWith('Exception: ')) {
    return text.substring('Exception: '.length).trim();
  }
  return text;
}
