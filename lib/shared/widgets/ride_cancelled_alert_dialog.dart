library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import 'confirmation_action_column.dart';
import 'fraya_dialog.dart';

enum RideCancelledAlertAction { primary, secondary, timedOut }

Future<RideCancelledAlertAction> showRideCancelledAlertDialog(
  BuildContext context, {
  required String message,
  required String actionLabel,
  String? secondaryActionLabel,
  Duration autoRedirectAfter = const Duration(seconds: 10),
}) async {
  final action = await showDialog<RideCancelledAlertAction>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _RideCancelledAlertDialog(
      message: message,
      actionLabel: actionLabel,
      secondaryActionLabel: secondaryActionLabel,
      autoRedirectAfter: autoRedirectAfter,
    ),
  );
  return action ?? RideCancelledAlertAction.timedOut;
}

class _RideCancelledAlertDialog extends StatefulWidget {
  const _RideCancelledAlertDialog({
    required this.message,
    required this.actionLabel,
    required this.secondaryActionLabel,
    required this.autoRedirectAfter,
  });

  final String message;
  final String actionLabel;
  final String? secondaryActionLabel;
  final Duration autoRedirectAfter;

  @override
  State<_RideCancelledAlertDialog> createState() =>
      _RideCancelledAlertDialogState();
}

class _RideCancelledAlertDialogState extends State<_RideCancelledAlertDialog> {
  Timer? _timer;
  late int _secondsRemaining;
  bool _isClosing = false;
  bool _allowPop = false;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.autoRedirectAfter.inSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), _handleTick);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _handleTick(Timer timer) {
    if (_secondsRemaining <= 1) {
      setState(() => _secondsRemaining = 0);
      _close(RideCancelledAlertAction.timedOut);
      return;
    }
    setState(() => _secondsRemaining--);
  }

  void _close(RideCancelledAlertAction action) {
    if (_isClosing || !mounted) return;
    _isClosing = true;
    _timer?.cancel();
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(action);
    });
  }

  @override
  Widget build(BuildContext context) {
    final hPad = context.responsiveValue<double>(
      compact: 16,
      phone: 20,
      largePhone: 24,
      tablet: 32,
    );

    return PopScope(
      canPop: _allowPop,
      child: FrayaDialog(
        padding: EdgeInsets.fromLTRB(hPad, 32, hPad, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const FrayaDialogIcon(
              icon: Icons.cancel_outlined,
              color: AppColors.error,
            ),
            const SizedBox(height: 20),
            Text(
              'Course annulée',
              textAlign: TextAlign.center,
              style: context.textH2.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.message,
              textAlign: TextAlign.center,
              style: context.textSmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 16),
            _CountdownBadge(seconds: _secondsRemaining),
            const SizedBox(height: 24),
            ConfirmationActionColumn(
              primaryLabel: widget.actionLabel,
              onPrimaryPressed: () => _close(RideCancelledAlertAction.primary),
              secondaryLabel: widget.secondaryActionLabel,
              onSecondaryPressed: widget.secondaryActionLabel == null
                  ? null
                  : () => _close(RideCancelledAlertAction.secondary),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class _CountdownBadge extends StatelessWidget {
  const _CountdownBadge({required this.seconds});

  final int seconds;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.greyExtraLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.greyLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.timer_outlined,
              size: 14,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              'Redirection dans $seconds s',
              style: context.textSmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
