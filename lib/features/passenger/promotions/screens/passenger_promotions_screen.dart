import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../providers/passenger_promotions_provider.dart';

class PassengerPromotionsScreen extends ConsumerStatefulWidget {
  const PassengerPromotionsScreen({super.key});

  @override
  ConsumerState<PassengerPromotionsScreen> createState() =>
      _PassengerPromotionsScreenState();
}

class _PassengerPromotionsScreenState
    extends ConsumerState<PassengerPromotionsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(passengerPromotionsProvider, (previous, next) {
      final previousError = previous?.errorMessage;
      final nextError = next.errorMessage;
      if (nextError != null &&
          nextError.isNotEmpty &&
          previousError != nextError) {
        AppSnackBar.showError(context, nextError);
      }
    });
    final state = ref.watch(passengerPromotionsProvider);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.colors.textPrimary),
          onPressed: context.pop,
        ),
        title: Text(
          'Offres & Promotions',
          style: AppTextStyles.h3.copyWith(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Code promo', style: AppTextStyles.h4),
              const SizedBox(height: AppTheme.spacingSm),
              TextFormField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(hintText: 'Ex: FRAYA20'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Saisissez un code promo.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacingLg),
              Text('Montant initial (FCFA)', style: AppTextStyles.h4),
              const SizedBox(height: AppTheme.spacingSm),
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(hintText: 'Ex: 5000'),
                validator: (value) {
                  final parsed = double.tryParse(
                    (value ?? '').trim().replaceAll(',', '.'),
                  );
                  if (parsed == null || parsed <= 0) {
                    return 'Saisissez un montant valide.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacingLg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: state.isLoading ? null : _onApplyPressed,
                  child: state.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Appliquer le code'),
                ),
              ),
              const SizedBox(height: AppTheme.spacingLg),
              if (state.result != null) _ResultCard(state: state),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onApplyPressed() async {
    if (!_formKey.currentState!.validate()) return;
    final price = double.parse(
      _priceController.text.trim().replaceAll(',', '.'),
    );
    await ref
        .read(passengerPromotionsProvider.notifier)
        .applyCode(code: _codeController.text.trim(), initialPrice: price);
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.state});

  final PassengerPromotionsState state;

  @override
  Widget build(BuildContext context) {
    final result = state.result!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: context.colors.greyExtraLight.withValues(alpha: .45),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Code: ${result.promoCode}', style: AppTextStyles.h4),
          const SizedBox(height: 6),
          Text('Prix initial: ${result.originalPrice.toStringAsFixed(0)} FCFA'),
          Text('Reduction: -${result.discountAmount.toStringAsFixed(0)} FCFA'),
          Text(
            'Prix final: ${result.finalPrice.toStringAsFixed(0)} FCFA',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            result.message,
            style: AppTextStyles.small.copyWith(color: context.colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
