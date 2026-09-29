import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/providers/places_provider.dart';
import '../../../../shared/widgets/map/fraya_map.dart';
import '../providers/pickup_map_edit_controller.dart';
import '../widgets/pickup_center_pin_overlay.dart';

class MapAddressPickerScreen extends ConsumerStatefulWidget {
  const MapAddressPickerScreen({
    required this.target,
    required this.initialPosition,
    super.key,
  });

  final SearchType target;
  final LatLng initialPosition;

  @override
  ConsumerState<MapAddressPickerScreen> createState() =>
      _MapAddressPickerScreenState();
}

class _MapAddressPickerScreenState
    extends ConsumerState<MapAddressPickerScreen> {
  bool _isDragging = false;
  late LatLng _cameraCenter;

  // Moitié de la hauteur totale du pin (cercle 42 + tige 12) pour aligner
  // la pointe sur le centre caméra via Transform.translate.
  static const double _kPinHalfHeight = (42.0 + 12.0) / 2;

  @override
  void initState() {
    super.initState();
    _cameraCenter = widget.initialPosition;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(mapAddressEditControllerProvider(widget.target).notifier)
          .enterEditMode(widget.initialPosition);
    });
  }

  @override
  void dispose() {
    if (ref
        .read(mapAddressEditControllerProvider(widget.target))
        .isEditing) {
      ref
          .read(mapAddressEditControllerProvider(widget.target).notifier)
          .cancelEditing();
    }
    super.dispose();
  }

  void _onCameraMoveStarted() {
    ref
        .read(mapAddressEditControllerProvider(widget.target).notifier)
        .handleCameraMoveStarted();
    setState(() => _isDragging = true);
  }

  void _onCameraIdle() {
    setState(() => _isDragging = false);
    ref
        .read(mapAddressEditControllerProvider(widget.target).notifier)
        .handleCameraIdle(_cameraCenter);
  }

  Future<void> _confirm() async {
    await ref
        .read(mapAddressEditControllerProvider(widget.target).notifier)
        .confirmSelection();
    if (mounted) Navigator.pop(context);
  }

  void _cancel() {
    ref
        .read(mapAddressEditControllerProvider(widget.target).notifier)
        .cancelEditing();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final editState =
        ref.watch(mapAddressEditControllerProvider(widget.target));
    final isDestination = widget.target == SearchType.destination;
    final title = isDestination
        ? 'Ajuster la destination'
        : 'Ajuster le point de prise en charge';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await _confirm();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          // StackFit.expand force le Stack à remplir tout l'écran,
          // évitant que le SafeArea non-positionné ne contraigne sa hauteur.
          fit: StackFit.expand,
          children: [
            // Map plein écran
            FrayaMap(
              initialTarget: widget.initialPosition,
              initialZoom: 16.0,
              autoCenterOnUser: false,
              onCameraMoveStarted: _onCameraMoveStarted,
              onCameraMove: (pos) => _cameraCenter = pos.target,
              onCameraIdle: _onCameraIdle,
            ),
            // Pin centré sur le plein écran = camera center.
            // Transform.translate(-_kPinHalfHeight) aligne la POINTE du pin
            // (bas du widget) sur le centre caméra.
            Positioned.fill(
              child: Center(
                child: Transform.translate(
                  offset: const Offset(0, -_kPinHalfHeight),
                  child: PickupCenterPinOverlay(
                    isDragging: _isDragging,
                    isDestination: isDestination,
                  ),
                ),
              ),
            ),
            // Bouton × (annuler) — en haut à gauche
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  child: Row(
                    children: [
                      Material(
                        color: context.colors.surface,
                        shape: const CircleBorder(),
                        elevation: 2,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _cancel,
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(Icons.close, size: 22),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Card d'aperçu de l'adresse (sans boutons) — collé en bas
            Positioned(
              bottom: 0,
              left: AppTheme.spacingLg,
              right: AppTheme.spacingLg,
              child: SafeArea(
                top: false,
                left: false,
                right: false,
                child: Container(
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppTheme.radius2xl),
                    ),
                    boxShadow: AppColors.shadowLg,
                  ),
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spacingLg,
                    AppTheme.spacingMd,
                    AppTheme.spacingLg,
                    AppTheme.spacingLg,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                        style: AppTextStyles.h4.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingSm),
                      if (editState.isResolvingAddress || editState.isDragging)
                        Row(
                          children: [
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Positionnement en cours...',
                                style: AppTextStyles.body.copyWith(
                                  color: context.colors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          editState.draftAddress ??
                              editState.draftName ??
                              'Point sélectionné',
                          style: AppTextStyles.body.copyWith(
                            color: context.colors.textSecondary,
                          ),
                        ),
                      const SizedBox(height: AppTheme.spacingMd),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: (editState.isResolvingAddress ||
                                  editState.isDragging)
                              ? null
                              : _confirm,
                          child: const Text('Confirmer'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
