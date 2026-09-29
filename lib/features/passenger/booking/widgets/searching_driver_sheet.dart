import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/widgets/sheet_handle.dart';
import '../providers/booking_provider.dart';
import 'cancel_search_confirmation_dialog.dart';

class SearchingDriverSheet extends ConsumerStatefulWidget {
  const SearchingDriverSheet({
    super.key,
    this.scrollController,
    this.onRefresh,
  });
  final ScrollController? scrollController;
  final Future<void> Function()? onRefresh;

  @override
  ConsumerState<SearchingDriverSheet> createState() =>
      _SearchingDriverSheetState();
}

class _SearchingDriverSheetState extends ConsumerState<SearchingDriverSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radius2xl),
        ),
        boxShadow: AppColors.shadowLg,
      ),
      child: RefreshIndicator(
        onRefresh: widget.onRefresh ?? () async {},
        child: ListView(
          controller: widget.scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          shrinkWrap: true,
          padding: EdgeInsets.fromLTRB(
            context.horizontalPagePadding,
            AppTheme.spacingLg,
            context.horizontalPagePadding,
            AppTheme.spacingLg,
          ),
          children: [
            const SheetHandle(),
            const SizedBox(height: AppTheme.spacingLg),

            // 1. Animation de radar
            _RadarAnimation(controller: _controller),
            const SizedBox(height: AppTheme.spacingLg),

            // 2. Texte de statut
            Center(
              child: Text(
                'Recherche en cours...',
                style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingLg,
              ),
              child: Text(
                'Nous trouvons le meilleur chauffeur vérifié pour vous',
                style: AppTextStyles.body.copyWith(
                  color: context.colors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // 3. Encadré d'information (Critères)
            // Container(
            //   padding: const EdgeInsets.all(AppTheme.spacingLg),
            //   decoration: BoxDecoration(
            //     color: AppColors.infoBackground.withValues(alpha: 0.3),
            //     borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            //   ),
            //   child: Column(
            //     crossAxisAlignment: CrossAxisAlignment.start,
            //     children: [
            //       Row(
            //         children: [
            //           const Icon(Icons.shield_outlined, color: AppColors.infoText, size: 20),
            //           const SizedBox(width: 12),
            //           Text(
            //             'Critères de sélection',
            //             style: AppTextStyles.small.copyWith(
            //               color: AppColors.infoText,
            //               fontWeight: FontWeight.bold,
            //             ),
            //           ),
            //         ],
            //       ),
            //       const SizedBox(height: 16),
            //       const _CriteriaItem(text: 'Chauffeurs vérifiés uniquement'),
            //       const SizedBox(height: 8),
            //       const _CriteriaItem(text: 'Note moyenne supérieure à 4.5/5'),
            //       const SizedBox(height: 8),
            //       const _CriteriaItem(text: 'Véhicules en bon état'),
            //     ],
            //   ),
            // ),
            // const SizedBox(height: AppTheme.spacing2xl),

            // 4. Bouton d'annulation (Texte souligné)
            Center(
              child: TextButton(
                onPressed: _confirmCancelSearch,
                child: Text(
                  'Annuler',
                  style: AppTextStyles.body.copyWith(
                    color: context.colors.textSecondary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmCancelSearch() async {
    final confirmed = await showCancelSearchConfirmationDialog(context);
    if (!mounted || !confirmed) return;
    await ref
        .read(bookingFlowProvider.notifier)
        .cancelSearching(reason: 'Recherche annulée par le passager');
  }
}

class _RadarAnimation extends StatelessWidget {
  const _RadarAnimation({required this.controller});
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    final radarSize = context.responsiveValue<double>(
      compact: 100,
      phone: 120,
      largePhone: 130,
      tablet: 160,
    );
    return SizedBox(
      height: radarSize,
      width: radarSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _PulseCircle(
            controller: controller,
            delay: 0.0,
            radarSize: radarSize,
          ),
          _PulseCircle(
            controller: controller,
            delay: 0.5,
            radarSize: radarSize,
          ),
          _PulseCircle(
            controller: controller,
            delay: 1.0,
            radarSize: radarSize,
          ),
          Container(
            padding: EdgeInsets.all(radarSize * 0.13),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x33FDB913),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.directions_car_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseCircle extends StatelessWidget {
  const _PulseCircle({
    required this.controller,
    required this.delay,
    required this.radarSize,
  });
  final AnimationController controller;
  final double delay;
  final double radarSize;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        double value = (controller.value + delay) % 1.0;
        final minRadius = radarSize * 0.5;
        final maxRadius = radarSize * 1.5;
        final current = minRadius + (value * (maxRadius - minRadius));
        return Container(
          width: current,
          height: current,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 1.0 - value),
              width: 2,
            ),
          ),
        );
      },
    );
  }
}
