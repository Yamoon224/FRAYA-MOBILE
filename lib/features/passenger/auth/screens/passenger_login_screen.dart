import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../shared/models/auth_state.dart';
import '../../../../shared/widgets/auth_login_layout.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../providers/passenger_auth_provider.dart';

class PassengerLoginScreen extends ConsumerStatefulWidget {
  const PassengerLoginScreen({super.key});

  @override
  ConsumerState<PassengerLoginScreen> createState() =>
      _PassengerLoginScreenState();
}

class _PassengerLoginScreenState extends ConsumerState<PassengerLoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    await ref
        .read(passengerAuthProvider.notifier)
        .login(_phoneController.text, _passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    // Écouter les changements d'état
    ref.listen<AuthState>(passengerAuthProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        context.goNamed(RouteNames.passengerHome);
      } else if (next.status == AuthStatus.error) {
        AppSnackBar.showError(
          context,
          next.errorMessage ?? 'Erreur de connexion',
        );
      }
    });

    final authState = ref.watch(passengerAuthProvider);

    return AuthLoginLayout(
      subtitle: 'Connectez-vous pour continuer vos déplacements',
      isPassenger: true,
      phoneController: _phoneController,
      passwordController: _passwordController,
      onLogin: _handleLogin,
      isLoading: authState.status == AuthStatus.loading,
      formKey: _formKey,
      onSignup: () => context.pushNamed(RouteNames.register),
      onForgotPassword: () => context.pushNamed(RouteNames.forgotPassword),
    );
  }
}
