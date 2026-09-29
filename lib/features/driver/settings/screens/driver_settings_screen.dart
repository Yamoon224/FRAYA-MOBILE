library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/account_deletion_controller.dart';
import '../../../../shared/models/support_topic.dart';
import '../../../../shared/screens/support/support_screen.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/settings/app_settings_screen.dart';
import '../../../../shared/widgets/settings/delete_account_confirmation_dialog.dart';
import '../../../../shared/widgets/legal_document_dialog.dart';
import '../../../../shared/widgets/settings/legal_web_screen.dart';
import '../providers/driver_settings_provider.dart';
import 'driver_notifications_screen.dart';
import 'driver_security_screen.dart';

class DriverSettingsScreen extends ConsumerWidget {
  const DriverSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(driverSettingsProvider);
    final deletionState = ref.watch(accountDeletionControllerProvider);
    final sections = <AppSettingsSection>[
      // AppSettingsSection(
      //   title: 'Compte',
      //   items: [
      //     AppSettingsItem(
      //       icon: Icons.person_outline,
      //       iconColor: const Color(0xFF2563EB),
      //       title: 'Mon profil',
      //       onTap: () => _push(context, const DriverProfileScreen()),
      //     ),
      //   ],
      // ),
      AppSettingsSection(
        title: 'Préférences',
        items: [
          AppSettingsItem(
            icon: Icons.notifications_none_rounded,
            iconColor: const Color(0xFF2563EB),
            title: 'Notifications',
            value: settings.notificationsEnabled ? 'Activées' : 'Désactivées',
            onTap: () => _push(context, const DriverNotificationsScreen()),
          ),
          // AppSettingsItem(
          //   icon: Icons.language_rounded,
          //   iconColor: const Color(0xFF16A34A),
          //   title: 'Langue',
          //   value: settings.languageCode.toLowerCase().startsWith('fr')
          //       ? 'Francais'
          //       : 'English',
          //   onTap: () =>
          //       _showLanguageSheet(context, ref, settings.languageCode),
          // ),
          AppSettingsItem(
            icon: Icons.dark_mode_outlined,
            iconColor: const Color(0xFF7E22CE),
            title: 'Mode sombre',
            value: settings.darkModeEnabled ? 'Activé' : 'Désactivé',
            onTap: () =>
                ref.read(driverSettingsProvider.notifier).toggleDarkMode(),
          ),
          AppSettingsItem(
            icon: Icons.volume_up_outlined,
            iconColor: const Color(0xFFD97706),
            title: 'Sons',
            value: settings.soundsEnabled ? 'Actifs' : 'Désactivés',
            onTap: () =>
                ref.read(driverSettingsProvider.notifier).toggleSounds(),
          ),
        ],
      ),
      AppSettingsSection(
        title: 'Sécurité & Confidentialité',
        items: [
          AppSettingsItem(
            icon: Icons.shield_outlined,
            iconColor: Colors.red,
            title: 'Sécurité du compte',
            onTap: () => _push(context, const DriverSecurityScreen()),
          ),
          AppSettingsItem(
            icon: Icons.description_outlined,
            iconColor: const Color(0xFF475569),
            title: 'Politique de confidentialité',
            onTap: () => _push(
              context,
              const LegalWebScreen(
                title: 'Politique de confidentialité',
                url: 'https://manager.frayataxi.ci/privacy-policy',
              ),
            ),
          ),
          AppSettingsItem(
            icon: Icons.article_outlined,
            iconColor: const Color(0xFF475569),
            title: "Conditions d'utilisation",
            onTap: () => showLegalPdfDialog(
              context,
              title: "Conditions d'utilisation",
              uri: Uri.parse(
                'https://manager.frayataxi.ci/legal/cgu-fraya-taxi.pdf',
              ),
            ),
          ),
          AppSettingsItem(
            icon: Icons.receipt_long_outlined,
            iconColor: const Color(0xFF475569),
            title: 'Conditions générales de vente',
            onTap: () => showLegalPdfDialog(
              context,
              title: 'Conditions générales de vente',
              uri: Uri.parse(
                'https://manager.frayataxi.ci/legal/cgv-fraya-taxi-sa.pdf',
              ),
            ),
          ),
        ],
      ),
      AppSettingsSection(
        title: 'Support',
        items: [
          AppSettingsItem(
            icon: Icons.help_outline_rounded,
            iconColor: const Color(0xFF2563EB),
            title: "Centre d'aide",
            onTap: () => _push(
              context,
              const SupportScreen(
                audience: SupportAudience.driver,
                title: "Centre d'aide",
              ),
            ),
          ),
          AppSettingsItem(
            icon: Icons.contact_support_outlined,
            iconColor: const Color(0xFF2563EB),
            title: 'Contactez-nous',
            onTap: () => _push(
              context,
              const SupportScreen(
                audience: SupportAudience.driver,
                title: 'Contactez-nous',
              ),
            ),
          ),
        ],
      ),
    ];

    return AppSettingsScreen(
      title: 'Paramètres',
      sections: sections,
      footer: const AppSettingsVersionCard(),
      bottomAction: AppSettingsDangerAction(
        label: 'Supprimer mon compte',
        isLoading: deletionState.isSubmitting,
        onTap: () => _deleteAccount(context, ref),
      ),
    );
  }

  static void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  static Future<void> _deleteAccount(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDeleteAccountConfirmationDialog(context);
    if (!confirmed) return;

    final success = await ref
        .read(accountDeletionControllerProvider.notifier)
        .deleteDriverAccount();
    if (!context.mounted) return;

    final state = ref.read(accountDeletionControllerProvider);
    if (success) {
      AppSnackBar.showSuccess(context, 'Compte supprimé avec succès.');
    } else if (state.errorMessage != null) {
      AppSnackBar.showError(context, state.errorMessage!);
    }
    ref.read(accountDeletionControllerProvider.notifier).clearFeedback();
  }

  // ignore: unused_element
  static Future<void> _showLanguageSheet(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Français'),
              trailing: current == 'fr' ? const Icon(Icons.check) : null,
              onTap: () {
                ref.read(driverSettingsProvider.notifier).setLanguage('fr');
                Navigator.pop(sheetContext);
              },
            ),
            ListTile(
              title: const Text('English'),
              trailing: current == 'en' ? const Icon(Icons.check) : null,
              onTap: () {
                ref.read(driverSettingsProvider.notifier).setLanguage('en');
                Navigator.pop(sheetContext);
              },
            ),
          ],
        ),
      ),
    );
  }
}
