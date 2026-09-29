import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/settings/account_security_screen.dart';
import '../providers/driver_security_provider.dart';

class DriverSecurityScreen extends ConsumerWidget {
  const DriverSecurityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(driverSecurityProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage!.isNotEmpty) {
        AppSnackBar.showError(context, next.errorMessage!);
      } else if (next.success) {
        AppSnackBar.showSuccess(context, 'Mot de passe modifié avec succès.');
        ref.read(driverSecurityProvider.notifier).clearFeedback();
      }
    });
    final state = ref.watch(driverSecurityProvider);

    return AccountSecurityScreen(
      isSubmitting: state.isSubmitting,
      onSubmit: (oldPassword, newPassword) {
        return ref.read(driverSecurityProvider.notifier).changePassword(
          oldPassword: oldPassword,
          newPassword: newPassword,
        );
      },
    );
  }
}
