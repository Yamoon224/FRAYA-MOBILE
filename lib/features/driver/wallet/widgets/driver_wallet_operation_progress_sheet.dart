library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/app_theme.dart';
import '../models/driver_wallet_operation_result.dart';

class DriverWalletOperationProgressSheet extends StatelessWidget {
  const DriverWalletOperationProgressSheet({
    super.key,
    required this.operationType,
  });

  final DriverWalletOperationType operationType;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              'Traitement en cours',
              textAlign: TextAlign.center,
              style: AppTextStyles.h2,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              _description,
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),
          ],
        ),
      ),
    );
  }

  String get _description {
    return switch (operationType) {
      DriverWalletOperationType.reload =>
        'Votre demande de rechargement est en cours.',
      DriverWalletOperationType.packageSubscription =>
        'Votre souscription est en cours de traitement.',
    };
  }
}
