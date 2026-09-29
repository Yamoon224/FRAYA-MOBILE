import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../providers/payment_method_provider.dart';

class PaymentMethodSelector extends StatelessWidget {
  const PaymentMethodSelector({
    super.key,
    required this.selectedMethod,
    required this.onMethodSelected,
  });

  final PaymentMethod selectedMethod;
  final Function(PaymentMethod) onMethodSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mode de paiement',
          style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        SizedBox(
          height: 76,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: PaymentMethod.values.map((method) {
              return _PaymentMethodChip(
                method: method,
                isSelected: selectedMethod == method,
                onTap: () => onMethodSelected(method),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _PaymentMethodChip extends StatelessWidget {
  const _PaymentMethodChip({
    required this.method,
    required this.isSelected,
    required this.onTap,
  });

  final PaymentMethod method;
  final bool isSelected;
  final VoidCallback onTap;

  Color get _brandColor {
    switch (method) {
      case PaymentMethod.cash:
        return const Color(0xFF4CAF50);
      case PaymentMethod.wave:
        return const Color(0xFF0057FF);
      case PaymentMethod.orangeMoney:
        return const Color(0xFFFF6600);
      case PaymentMethod.mtnMoney:
        return const Color(0xFFFFCC00);
      case PaymentMethod.moovMoney:
        return const Color(0xFF009BDE);
    }
  }

  String? get _logoAsset {
    switch (method) {
      case PaymentMethod.cash:
        return null;
      case PaymentMethod.wave:
        return 'assets/images/wave.png';
      case PaymentMethod.orangeMoney:
        return 'assets/images/orange-money.png';
      case PaymentMethod.mtnMoney:
        return 'assets/images/mobile-money.png';
      case PaymentMethod.moovMoney:
        return 'assets/images/moov.jpg';
    }
  }

  Widget _buildIcon() {
    final asset = _logoAsset;
    if (asset == null) {
      return Icon(Icons.payments_rounded, color: _brandColor, size: 18);
    }
    return Image.asset(asset, width: 22, height: 22, fit: BoxFit.contain);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? _brandColor.withValues(alpha: 0.08)
              : context.colors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: isSelected ? _brandColor : context.colors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _logoAsset == null
                    ? _brandColor.withValues(alpha: isSelected ? 0.15 : 0.1)
                    : context.colors.surface,
                shape: BoxShape.circle,
              ),
              child: Center(child: _buildIcon()),
            ),
            const SizedBox(height: 4),
            Text(
              method.label,
              style: AppTextStyles.xs.copyWith(
                color: isSelected ? _brandColor : context.colors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
