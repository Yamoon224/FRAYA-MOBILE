library;

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../domain/models/orange_money_payment.dart';
import '../providers/orange_money_payment_tracker.dart';

/// Page de règlement Orange Money. Se ferme seule avec l'issue du paiement ; fermée à la main,
/// elle renvoie `null` et l'appelant fait une dernière vérification auprès du serveur.
class DriverOrangeMoneyPaymentScreen extends StatefulWidget {
  const DriverOrangeMoneyPaymentScreen({
    super.key,
    required this.payment,
    required this.check,
  });

  final OrangeMoneyPayment payment;
  final Future<OrangeMoneyPaymentStatus> Function() check;

  @override
  State<DriverOrangeMoneyPaymentScreen> createState() =>
      _DriverOrangeMoneyPaymentScreenState();
}

class _DriverOrangeMoneyPaymentScreenState
    extends State<DriverOrangeMoneyPaymentScreen> {
  late final WebViewController _controller;
  late final OrangeMoneyPaymentTracker _tracker;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _tracker = OrangeMoneyPaymentTracker(
      check: widget.check,
      onOutcome: _onOutcome,
    )..start();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          // Orange renvoie l'utilisateur sur la page de statut du serveur : on vérifie tout de suite.
          onNavigationRequest: (request) {
            if (request.url.contains('/orange-money/callback')) {
              _tracker.pollNow();
            }
            return NavigationDecision.navigate;
          },
          onPageStarted: (_) => setState(() {
            _isLoading = true;
            _hasError = false;
          }),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onWebResourceError: (error) {
            if (error.isForMainFrame ?? true) {
              setState(() {
                _isLoading = false;
                _hasError = true;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.payment.paymentUrl));
  }

  void _onOutcome(OrangeMoneyPaymentStatus outcome) {
    if (!mounted) return;
    Navigator.of(context).pop(outcome);
  }

  @override
  void dispose() {
    _tracker.dispose();
    super.dispose();
  }

  void _retry() {
    setState(() {
      _hasError = false;
      _isLoading = true;
    });
    _controller.loadRequest(Uri.parse(widget.payment.paymentUrl));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : Colors.white;
    final titleColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        foregroundColor: titleColor,
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Fermer',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Paiement Orange Money',
          style: AppTextStyles.h3.copyWith(
            color: titleColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
        bottom: _isLoading
            ? const PreferredSize(
                preferredSize: Size.fromHeight(3),
                child: LinearProgressIndicator(
                  color: AppColors.primaryDark,
                  backgroundColor: Colors.transparent,
                ),
              )
            : null,
      ),
      body: _hasError
          ? _PaymentErrorView(onRetry: _retry)
          : WebViewWidget(controller: _controller),
    );
  }
}

class _PaymentErrorView extends StatelessWidget {
  const _PaymentErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 44),
            const SizedBox(height: 12),
            const Text(
              'Impossible de charger la page de paiement.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}
