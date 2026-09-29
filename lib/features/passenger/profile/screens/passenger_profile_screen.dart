import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../domain/models/special_offer.dart';
import '../../../../shared/providers/special_offer_provider.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/settings/logout_confirmation_dialog.dart';
import '../models/profile_model.dart';
import '../providers/profile_dependencies.dart';
import '../providers/profile_provider.dart';
import '../widgets/profile_edit_dialog.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_menu_item.dart';
import '../widgets/profile_phone_change_dialog.dart';
import '../widgets/profile_stats_card.dart';
import '../widgets/saved_places_section.dart';

class MyPassengerProfileScreen extends ConsumerWidget {
  const MyPassengerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(passengerProfileProvider);
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
          'Profil',
          style: AppTextStyles.h3.copyWith(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: [
          profileAsync.when(
            data: (profile) => IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => ProfileEditDialog(profile: profile),
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, stack) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(passengerProfileProvider);
          await ref.read(passengerProfileProvider.future);
        },
        child: profileAsync.when(
          data: (profile) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: _ProfileBody(profile: profile),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverFillRemaining(child: Center(child: Text('Erreur: $error'))),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.profile});

  final PassengerProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUploading = ref.watch(profileControllerProvider).isSubmitting;
    final promotionsCountAsync = ref.watch(
      activeSpecialOfferCountProvider(SpecialOfferAudience.passenger),
    );
    return Column(
      children: [
        ProfileHeader(
          profile: profile,
          onPhotoTap: isUploading ? null : () => _showPhotoPicker(context, ref),
          isUploading: isUploading,
        ),
        const SizedBox(height: 8),
        ProfileStatsCard(profile: profile),
        const SizedBox(height: 24),
        Divider(height: 1, color: context.colors.border),
        const SizedBox(height: 16),
        const SavedPlacesSection(),
        const SizedBox(height: 24),
        Divider(height: 1, color: context.colors.border),
        ProfileMenuItem(
          icon: Icons.phone_outlined,
          title: 'Modifier mon numéro',
          onTap: () => showDialog<void>(
            context: context,
            builder: (_) => const ProfilePhoneChangeDialog(),
          ),
        ),
        ProfileMenuItem(
          icon: Icons.favorite_border,
          title: 'Favoris',
          onTap: () => context.pushNamed(RouteNames.favorites),
        ),
        // ProfileMenuItem(
        //   icon: Icons.card_giftcard,
        //   title: 'Offres & Promotions',
        //   badge: promotionsBadge,
        //   onTap: () => context.pushNamed(RouteNames.promotions),
        // ),
        Divider(height: 1, color: context.colors.greyExtraLight),
        const SizedBox(height: 16),
        ProfileMenuItem(
          icon: Icons.logout,
          title: 'Déconnexion',
          isDestructive: true,
          onTap: () => _confirmLogout(context, ref),
        ),
        const SizedBox(height: 32),
        Text(
          profile.memberSince.isEmpty
              ? 'Membre depuis --'
              : 'Membre depuis ${profile.memberSince}',
          style: AppTextStyles.body.copyWith(
            color: context.colors.textTertiary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showLogoutConfirmationDialog(context);
    if (!confirmed) return;
    await ref.read(profileControllerProvider.notifier).logout();
  }

  Future<void> _showPhotoPicker(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Prendre une photo'),
              onTap: () async {
                Navigator.pop(sheetContext);
                await _pickAndUpload(context, ref, fromCamera: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choisir dans la galerie'),
              onTap: () async {
                Navigator.pop(sheetContext);
                await _pickAndUpload(context, ref, fromCamera: false);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUpload(
    BuildContext context,
    WidgetRef ref, {
    required bool fromCamera,
  }) async {
    final picker = ref.read(profilePhotoPickerProvider);
    final file = fromCamera
        ? await picker.pickFromCamera()
        : await picker.pickFromGallery();
    if (file == null) return;

    await ref
        .read(profileControllerProvider.notifier)
        .updateProfilePhoto(filePath: file.path, fileName: file.name);
    if (!context.mounted) return;

    final state = ref.read(profileControllerProvider);
    if (state.success) {
      ref.read(profileControllerProvider.notifier).clearFeedback();
      AppSnackBar.showSuccess(context, 'Photo de profil mise à jour');
    } else if (state.errorMessage != null) {
      ref.read(profileControllerProvider.notifier).clearFeedback();
      AppSnackBar.showError(context, state.errorMessage!);
    }
  }
}
