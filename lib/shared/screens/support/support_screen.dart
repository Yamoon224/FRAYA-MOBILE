library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/extensions.dart';
import '../../models/support_topic.dart';
import '../../providers/support_provider.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/fraya_button.dart';
import '../../widgets/selectable_option_tile.dart';

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key, required this.audience, required this.title});

  final SupportAudience audience;
  final String title;

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  SupportTopic? _selectedTopic;
  bool _isOpening = false;

  @override
  Widget build(BuildContext context) {
    final topics = ref.watch(supportTopicsProvider(widget.audience));
    final selectedTopic = _selectedTopic ?? topics.first;
    final controller = ref.watch(supportControllerProvider);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        foregroundColor: context.colors.textPrimary,
        title: Text(
          widget.title,
          style: AppTextStyles.h4.copyWith(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        children: [
          _SupportHeroCard(audience: widget.audience),
          const SizedBox(height: AppTheme.spacingMd),
          _SupportSectionCard(
            title: 'Choisissez un motif',
            child: Column(
              children: [
                for (final topic in topics)
                  SelectableOptionTile(
                    label: topic.label,
                    selected: topic.id == selectedTopic.id,
                    onTap: () => setState(() => _selectedTopic = topic),
                    activeColor: AppColors.primaryDark,
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          _SupportSectionCard(
            title: 'Message pre-rempli',
            child: _MessagePreview(
              message: controller.buildMessage(
                audience: widget.audience,
                topic: selectedTopic,
              ),
              description: selectedTopic.description,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          FrayaButton(
            label: 'Discuter sur WhatsApp',
            leftIcon: Icons.chat_bubble_outline_rounded,
            isLoading: _isOpening,
            onPressed: _isOpening ? null : () => _openSupport(selectedTopic),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            'Solution temporaire en attendant l\'integration du module de chat complet.',
            style: AppTextStyles.small.copyWith(color: context.colors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _openSupport(SupportTopic topic) async {
    setState(() => _isOpening = true);
    final errorMessage = await ref
        .read(supportControllerProvider)
        .openTopic(audience: widget.audience, topic: topic);
    if (!mounted) return;
    setState(() => _isOpening = false);
    if (errorMessage != null) {
      AppSnackBar.showError(context, errorMessage);
    }
  }
}

class _SupportHeroCard extends StatelessWidget {
  const _SupportHeroCard({required this.audience});

  final SupportAudience audience;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: context.colors.border),
        boxShadow: AppColors.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: Icon(
              Icons.support_agent_rounded,
              color: context.colors.textPrimary,
              size: 28,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            'Support ${audience.roleLabel.toLowerCase()}',
            style: AppTextStyles.h3.copyWith(
              color: context.colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            'Choisissez le sujet qui vous concerne puis ouvrez WhatsApp avec un message deja prepare pour notre equipe.',
            style: AppTextStyles.body.copyWith(color: context.colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _SupportSectionCard extends StatelessWidget {
  const _SupportSectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: context.colors.greyLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.h4.copyWith(
              color: context.colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          child,
        ],
      ),
    );
  }
}

class _MessagePreview extends StatelessWidget {
  const _MessagePreview({required this.message, required this.description});

  final String message;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: context.colors.surfacePressed,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            description,
            style: AppTextStyles.small.copyWith(color: context.colors.textSecondary),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(message, style: AppTextStyles.body.copyWith(color: context.colors.textPrimary)),
        ],
      ),
    );
  }
}
