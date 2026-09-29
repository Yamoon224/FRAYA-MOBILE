import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../providers/pickup_map_edit_controller.dart';

class PickupEditSheetContent extends StatelessWidget {
  const PickupEditSheetContent({
    super.key,
    required this.title,
    required this.state,
    required this.onConfirm,
    required this.onOpenTextSearch,
    required this.onCancel,
    this.scrollController,
  });

  final String title;
  final MapAddressEditState state;
  final VoidCallback onConfirm;
  final VoidCallback onOpenTextSearch;
  final VoidCallback onCancel;
  final ScrollController? scrollController;

  static const _padding = EdgeInsets.fromLTRB(
    AppTheme.spacingLg,
    AppTheme.spacingMd,
    AppTheme.spacingLg,
    AppTheme.spacingLg,
  );

  @override
  Widget build(BuildContext context) {
    final canConfirm = !state.isResolvingAddress && state.draftLatLng != null;
    final addressText = state.isResolvingAddress
        ? 'Recherche...'
        : (state.draftAddress ?? state.draftName ?? 'Point sélectionné');

    final children = _buildChildren(
      context: context,
      canConfirm: canConfirm,
      addressText: addressText,
    );

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radius2xl),
        ),
        boxShadow: AppColors.shadowLg,
      ),
      child: scrollController != null
          ? ListView(
              controller: scrollController,
              padding: _padding,
              shrinkWrap: true,
              children: children,
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: _padding,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: children,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  List<Widget> _buildChildren({
    required BuildContext context,
    required bool canConfirm,
    required String addressText,
  }) {
    return [
      Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: context.colors.greyLight,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
      const SizedBox(height: AppTheme.spacingMd),
      Text(
        title,
        style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: AppTheme.spacingSm),
      Text(
        addressText,
        style: AppTextStyles.body.copyWith(color: context.colors.textSecondary),
      ),
      if (state.errorText != null) ...[
        const SizedBox(height: AppTheme.spacingSm),
        Text(
          state.errorText!,
          style: AppTextStyles.small.copyWith(color: AppColors.error),
        ),
      ],
      const SizedBox(height: AppTheme.spacingLg),
      ElevatedButton(
        onPressed: canConfirm ? onConfirm : null,
        child: const Text('Confirmer ce point'),
      ),
      const SizedBox(height: AppTheme.spacingSm),
      OutlinedButton(
        onPressed: onOpenTextSearch,
        child: const Text('Rechercher une adresse'),
      ),
      const SizedBox(height: AppTheme.spacingXs),
      Center(
        child: TextButton(
          onPressed: onCancel,
          child: Text(
            'Annuler',
            style: AppTextStyles.body.copyWith(
              color: context.colors.textSecondary,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ),
    ];
  }
}
