library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/extensions.dart';
import '../../../../../shared/widgets/fraya_button.dart';
import '../models/driver_wallet_operation_result.dart';

class DriverWalletPaymentSheet extends StatefulWidget {
  const DriverWalletPaymentSheet({
    super.key,
    required this.title,
    required this.confirmLabel,
    required this.onSubmit,
    this.initialAmount,
    this.initialMethod,
  });

  final String title;
  final String confirmLabel;
  final double? initialAmount;
  final String? initialMethod;
  final Future<void> Function(DriverWalletReloadDraft draft) onSubmit;

  @override
  State<DriverWalletPaymentSheet> createState() =>
      _DriverWalletPaymentSheetState();
}

class _DriverWalletPaymentSheetState extends State<DriverWalletPaymentSheet> {
  late final TextEditingController _amountController;
  static const List<_PaymentMethod> _methods = <_PaymentMethod>[
    _PaymentMethod(
      id: 'wave',
      name: 'Wave',
      assetPath: 'assets/images/wave.png',
    ),
    _PaymentMethod(
      id: 'orange_money',
      name: 'Orange Money',
      assetPath: 'assets/images/orange-money.png',
    ),
    _PaymentMethod(
      id: 'mtn_momo',
      name: 'MTN MoMo',
      assetPath: 'assets/images/mobile-money.png',
    ),
    _PaymentMethod(
      id: 'moov_money',
      name: 'Moov Money',
      assetPath: 'assets/images/moov.jpg',
    ),
  ];
  late String _selectedMethod;
  String? _localError;
  bool _isLocked = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.initialAmount?.toStringAsFixed(0) ?? '',
    );
    _selectedMethod = widget.initialMethod ?? _methods.first.id;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  bool get _isBusy => _isLocked;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.minHeight),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(widget.title, style: AppTextStyles.h1),
                      ),
                      IconButton(
                        onPressed: _isBusy
                            ? null
                            : () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choisissez un moyen de paiement',
                    style: AppTextStyles.h3.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Montant (FCFA)',
                      hintText: 'Ex: 5000',
                      errorText: _localError,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    itemCount: _methods.length,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.35,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemBuilder: (context, index) {
                      final method = _methods[index];
                      final isSelected = _selectedMethod == method.id;
                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _isBusy
                            ? null
                            : () => setState(() => _selectedMethod = method.id),
                        child: Container(
                          decoration: BoxDecoration(
                            color: context.colors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryDark
                                  : context.colors.greyLight,
                              width: isSelected ? 1.6 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Image.asset(
                                  method.assetPath,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                method.name,
                                style: AppTextStyles.body,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  FrayaButton(
                    label: widget.confirmLabel,
                    isLoading: _isBusy,
                    onPressed: _isBusy ? null : _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final value = double.tryParse(
      _amountController.text.trim().replaceAll(',', '.'),
    );
    if (value == null || value <= 0) {
      setState(() => _localError = 'Saisissez un montant valide.');
      return;
    }
    setState(() {
      _localError = null;
      _isLocked = true;
    });
    await widget.onSubmit(
      DriverWalletReloadDraft(amount: value, paymentMethod: _selectedMethod),
    );
    if (mounted) {
      setState(() => _isLocked = false);
    }
  }
}

class _PaymentMethod {
  const _PaymentMethod({
    required this.id,
    required this.name,
    required this.assetPath,
  });

  final String id;
  final String name;
  final String assetPath;
}
