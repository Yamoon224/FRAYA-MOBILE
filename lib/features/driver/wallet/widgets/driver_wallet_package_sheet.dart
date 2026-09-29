library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/extensions.dart';
import '../../../../../domain/models/driver_wallet_package.dart';
import '../../../../../shared/widgets/fraya_button.dart';

class DriverWalletPackageSheet extends StatefulWidget {
  const DriverWalletPackageSheet({
    super.key,
    required this.packages,
    required this.isLoading,
    required this.walletBalanceText,
    required this.onRefresh,
    required this.onConfirmPackage,
    this.initialSelectedPackage,
  });

  final List<DriverWalletPackage> packages;
  final bool isLoading;
  final String walletBalanceText;
  final VoidCallback onRefresh;
  final Future<void> Function(DriverWalletPackage package) onConfirmPackage;
  final DriverWalletPackage? initialSelectedPackage;

  static final NumberFormat _currency = NumberFormat('#,###', 'fr_FR');

  @override
  State<DriverWalletPackageSheet> createState() =>
      _DriverWalletPackageSheetState();
}

class _DriverWalletPackageSheetState extends State<DriverWalletPackageSheet> {
  DriverWalletPackage? _selectedPackage;
  bool _isLocked = false;

  @override
  void initState() {
    super.initState();
    _selectedPackage = _resolveSelection(
      widget.packages,
      preferred: widget.initialSelectedPackage,
    );
  }

  @override
  void didUpdateWidget(covariant DriverWalletPackageSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextSelection = _resolveSelection(
      widget.packages,
      preferred: widget.initialSelectedPackage,
      current: _selectedPackage,
    );
    if (nextSelection?.id != _selectedPackage?.id) {
      _selectedPackage = nextSelection;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PackageHeader(
                title: 'Souscription au package',
                canGoBack: _canGoBack,
                isLocked: _isLocked,
                onBack: () => setState(() => _selectedPackage = null),
                onClose: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 10),
              Text(
                _subtitle,
                style: AppTextStyles.body.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (widget.isLoading && widget.packages.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (widget.packages.isEmpty) {
      return _PackageEmptyState(onRefresh: widget.onRefresh);
    }
    final selectedPackage = _selectedPackage;
    if (selectedPackage != null) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SummaryCard(
              package: selectedPackage,
              priceText: _priceText(selectedPackage),
            ),
            const SizedBox(height: 14),
            Text(
              'Paiement depuis votre wallet',
              style: AppTextStyles.h3.copyWith(color: context.colors.textSecondary),
            ),
            const SizedBox(height: 12),
            _WalletBalanceDisplay(balanceText: widget.walletBalanceText),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(text: _cycleLabel(selectedPackage.billingCycle)),
                _InfoChip(text: _rideLimitText(selectedPackage.maxRides)),
                _InfoChip(
                  text: '${selectedPackage.maxCancellations} annulations',
                ),
                if (selectedPackage.trialDays > 0)
                  _InfoChip(text: '${selectedPackage.trialDays} jours essai'),
              ],
            ),
            const SizedBox(height: 18),
            FrayaButton(
              label: 'Confirmer la souscription',
              leftIcon: Icons.check_rounded,
              isLoading: _isLocked,
              onPressed: _isLocked ? null : _submit,
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      itemCount: widget.packages.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final package = widget.packages[index];
        return _PackageTile(
          package: package,
          priceText: _priceText(package),
          onTap: () => setState(() => _selectedPackage = package),
        );
      },
    );
  }

  bool get _canGoBack => widget.packages.length > 1 && _selectedPackage != null;

  String get _subtitle {
    if (_selectedPackage != null) {
      return 'Votre wallet Fraya sera débité après confirmation.';
    }
    if (widget.packages.length > 1) {
      return 'Sélectionnez un package pour voir son détail avant souscription.';
    }
    return 'Votre wallet Fraya sera débité après confirmation.';
  }

  String _priceText(DriverWalletPackage package) {
    final price = package.price;
    if (price == null) return 'Prix indisponible';
    return '${DriverWalletPackageSheet._currency.format(price)} FCFA';
  }

  DriverWalletPackage? _resolveSelection(
    List<DriverWalletPackage> packages, {
    DriverWalletPackage? preferred,
    DriverWalletPackage? current,
  }) {
    if (packages.isEmpty) return null;
    if (preferred != null) {
      for (final package in packages) {
        if (package.id == preferred.id) return package;
      }
    }
    if (current != null) {
      for (final package in packages) {
        if (package.id == current.id) return package;
      }
    }
    if (packages.length == 1) return packages.single;
    return null;
  }

  Future<void> _submit() async {
    final package = _selectedPackage;
    if (package == null) return;
    setState(() => _isLocked = true);
    await widget.onConfirmPackage(package);
    if (mounted) {
      setState(() => _isLocked = false);
    }
  }
}

class _PackageHeader extends StatelessWidget {
  const _PackageHeader({
    required this.title,
    required this.canGoBack,
    required this.isLocked,
    required this.onBack,
    required this.onClose,
  });

  final String title;
  final bool canGoBack;
  final bool isLocked;
  final VoidCallback onBack;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (canGoBack)
          IconButton(
            onPressed: isLocked ? null : onBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        Expanded(child: Text(title, style: AppTextStyles.h1)),
        IconButton(
          onPressed: isLocked ? null : onClose,
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }
}

class _PackageTile extends StatelessWidget {
  const _PackageTile({
    required this.package,
    required this.priceText,
    required this.onTap,
  });

  final DriverWalletPackage package;
  final String priceText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: package.isRecommended
                ? AppColors.primaryDark
                : context.colors.greyLight,
            width: package.isRecommended ? 1.4 : 1,
          ),
          boxShadow: AppColors.shadowSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    package.name,
                    style: AppTextStyles.h3.copyWith(fontSize: 18),
                  ),
                ),
                if (package.isRecommended) const _RecommendedBadge(),
              ],
            ),
            if (package.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                package.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.small.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    priceText,
                    style: AppTextStyles.h2.copyWith(fontSize: 20),
                  ),
                ),
                Text(
                  _cycleLabel(package.billingCycle),
                  style: AppTextStyles.small.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(text: _rideLimitText(package.maxRides)),
                _InfoChip(text: '${package.maxCancellations} annulations'),
                if (package.trialDays > 0)
                  _InfoChip(text: '${package.trialDays} jours essai'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendedBadge extends StatelessWidget {
  const _RecommendedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Recommandé',
        style: AppTextStyles.small.copyWith(color: context.colors.textPrimary),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.colors.greyExtraLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: AppTextStyles.small.copyWith(color: context.colors.textSecondary),
      ),
    );
  }
}

class _WalletBalanceDisplay extends StatelessWidget {
  const _WalletBalanceDisplay({required this.balanceText});

  final String balanceText;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.colors.greyExtraLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.greyLight),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryDark.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              color: AppColors.primaryDark,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wallet Fraya',
                  style: AppTextStyles.small.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$balanceText FCFA',
                  style: AppTextStyles.h2.copyWith(fontSize: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.package, required this.priceText});

  final DriverWalletPackage package;
  final String priceText;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.greyExtraLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(package.name, style: AppTextStyles.h3)),
              if (package.isRecommended) const _RecommendedBadge(),
            ],
          ),
          const SizedBox(height: 8),
          Text(priceText, style: AppTextStyles.h2.copyWith(fontSize: 22)),
          if (package.description.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              package.description,
              style: AppTextStyles.small.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PackageEmptyState extends StatelessWidget {
  const _PackageEmptyState({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.colors.greyLight),
        ),
        child: Column(
          children: [
            const Icon(Icons.inventory_2_outlined, size: 32),
            const SizedBox(height: 8),
            Text(
              'Aucun package disponible.',
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Recharger'),
            ),
          ],
        ),
      ),
    );
  }
}

String _cycleLabel(String cycle) => switch (cycle) {
  'DAILY' => 'Journalier',
  'MONTHLY' => 'Mensuel',
  'ANNUAL' => 'Annuel',
  _ => cycle,
};

String _rideLimitText(int maxRides) {
  if (maxRides < 0) return 'Courses illimitées';
  return '$maxRides courses';
}
