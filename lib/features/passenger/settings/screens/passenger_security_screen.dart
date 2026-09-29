import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/settings/account_security_screen.dart';
import '../providers/passenger_security_provider.dart';

class PassengerSecurityScreen extends ConsumerWidget {
  const PassengerSecurityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(passengerSecurityProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage!.isNotEmpty) {
        AppSnackBar.showError(context, next.errorMessage!);
      } else if (next.success) {
        AppSnackBar.showSuccess(context, 'Mot de passe modifié avec succès.');
        ref.read(passengerSecurityProvider.notifier).clearFeedback();
      }
    });
    final state = ref.watch(passengerSecurityProvider);

    return AccountSecurityScreen(
      isSubmitting: state.isSubmitting,
      onSubmit: (oldPassword, newPassword) {
        return ref.read(passengerSecurityProvider.notifier).changePassword(
          oldPassword: oldPassword,
          newPassword: newPassword,
        );
      },
    );
  }
}
