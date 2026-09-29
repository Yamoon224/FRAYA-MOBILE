import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/extensions.dart';
import '../../../../../domain/usecases/passenger/report_ride_problem.dart';
import '../../../auth/providers/passenger_auth_provider.dart';
import '../../../auth/providers/passenger_auth_user_id.dart';
import '../../../../../shared/widgets/app_snack_bar.dart';
import '../../../../../shared/widgets/fraya_bottom_sheet_container.dart';
import '../../../../../shared/widgets/selectable_option_tile.dart';
import '../../../../../shared/widgets/sheet_handle.dart';
import '../../providers/booking_dependencies.dart';

class ReportProblemSheet extends ConsumerStatefulWidget {
  const ReportProblemSheet({super.key, required this.rideId});

  final String rideId;

  static void show(BuildContext context, String rideId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportProblemSheet(rideId: rideId),
    );
  }

  @override
  ConsumerState<ReportProblemSheet> createState() => _ReportProblemSheetState();
}

class _ReportProblemSheetState extends ConsumerState<ReportProblemSheet> {
  String? _selectedCategory;
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  static const _categories = [
    'Chauffeur impoli ou agressif',
    'Véhicule en mauvais état',
    'Itinéraire détourné',
    'Prix incorrect',
    'Chauffeur en retard',
    'Problème de sécurité',
    'Autre',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FrayaBottomSheetContainer(
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SheetHandle(),
          const SizedBox(height: AppTheme.spacingLg),
          Row(
            children: [
              Icon(
                Icons.flag_outlined,
                color: context.colors.textSecondary,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Signaler un probleme',
                  style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Aidez-nous a ameliorer le service en decrivant votre experience.',
            style: AppTextStyles.small.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._categories.map(
            (category) => SelectableOptionTile(
              label: category,
              selected: _selectedCategory == category,
              onTap: () => setState(() => _selectedCategory = category),
              activeColor: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            style: AppTextStyles.body,
            decoration: InputDecoration(
              hintText: 'Decrivez le probleme en detail... (optionnel)',
              hintStyle: AppTextStyles.small.copyWith(
                color: context.colors.textSecondary,
              ),
              filled: true,
              fillColor: context.colors.greyExtraLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(AppTheme.spacingMd),
            ),
          ),
        ],
      ),
      footer: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  (_selectedCategory == null || _isSubmitting) ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: context.colors.greyLight,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_outlined),
                    const SizedBox(width: AppTheme.spacingSm),
                    Text(
                      _isSubmitting
                          ? 'Envoi en cours...'
                          : 'Envoyer le signalement',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Annuler',
                style: AppTextStyles.body.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_selectedCategory == null || _isSubmitting) return;
    setState(() => _isSubmitting = true);
    final userId = passengerAuthUserIdFromData(
      ref.read(passengerAuthProvider).userData,
    );
    if (userId == null) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppSnackBar.showError(context, 'Utilisateur introuvable.');
      return;
    }
    final result = await ref.read(reportRideProblemUseCaseProvider).call(
          ReportRideProblemParams(
            rideId: widget.rideId,
            userId: userId,
            category: _selectedCategory!,
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
          ),
        );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    Navigator.pop(context);
    result.fold(
      (failure) => AppSnackBar.showError(
        context,
        failure.message.isNotEmpty
            ? failure.message
            : 'Impossible d\'envoyer le signalement.',
      ),
      (_) => AppSnackBar.showSuccess(
        context,
        'Signalement envoye. Merci pour votre retour.',
      ),
    );
  }
}
