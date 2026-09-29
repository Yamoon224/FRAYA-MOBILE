import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/providers/saved_places_provider.dart';
import 'saved_places/saved_place_tile.dart';
import 'saved_places/add_place_button.dart';

class SavedPlacesSection extends ConsumerStatefulWidget {
  const SavedPlacesSection({super.key});

  @override
  ConsumerState<SavedPlacesSection> createState() => _SavedPlacesSectionState();
}

class _SavedPlacesSectionState extends ConsumerState<SavedPlacesSection> {
  bool _isEditMode = false;

  void _toggleEditMode() => setState(() => _isEditMode = !_isEditMode);

  @override
  Widget build(BuildContext context) {
    final savedPlacesAsync = ref.watch(savedPlacesNotifierProvider);
    final hasPlaces = savedPlacesAsync.asData?.value.isNotEmpty ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Lieux enregistrés', style: AppTextStyles.h4),
              if (hasPlaces)
                TextButton(
                  onPressed: _toggleEditMode,
                  child: Text(
                    _isEditMode ? 'Terminé' : 'Modifier',
                    style: AppTextStyles.body.copyWith(
                      color: const Color(0xFFD4A843),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        savedPlacesAsync.when(
          data: (places) => Column(
            children: [
              ...places.map(
                (place) => SavedPlaceTile(
                  address: place,
                  isEditMode: _isEditMode,
                ),
              ),
              const SizedBox(height: 12),
              if (!_isEditMode) const AddPlaceButton(),
            ],
          ),
          loading: () => const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(20),
            child: Center(child: Text('Erreur: $e')),
          ),
        ),
      ],
    );
  }
}
