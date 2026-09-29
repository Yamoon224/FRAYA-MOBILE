import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/extensions.dart';

class AppSettingsSection {
  const AppSettingsSection({required this.title, required this.items});

  final String title;
  final List<AppSettingsItem> items;
}

class AppSettingsItem {
  const AppSettingsItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.value,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? value;
  final VoidCallback onTap;
}

class AppSettingsScreen extends ConsumerWidget {
  const AppSettingsScreen({
    super.key,
    required this.title,
    required this.sections,
    this.footer,
    this.bottomAction,
  });

  final String title;
  final List<AppSettingsSection> sections;
  final Widget? footer;
  final Widget? bottomAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backgroundColor = context.colors.background;
    final surfaceColor = context.colors.surface;
    final titleColor = context.colors.textPrimary;
    final footerWidgets = footer == null
        ? const <Widget>[]
        : <Widget>[footer!, const SizedBox(height: AppTheme.spacingMd)];
    final bottomActionWidgets = bottomAction == null
        ? const <Widget>[]
        : <Widget>[bottomAction!];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        foregroundColor: titleColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          title,
          style: AppTextStyles.h3.copyWith(
            color: titleColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        children: [
          for (final section in sections) ...[
            _SectionCard(
              title: section.title,
              items: section.items,
            ),
            const SizedBox(height: AppTheme.spacingMd),
          ],
          ...footerWidgets,
          ...bottomActionWidgets,
        ],
      ),
    );
  }
}

class AppSettingsVersionCard extends ConsumerWidget {
  const AppSettingsVersionCard({
    super.key,
    this.appName = 'FRAYA TAXI',
    this.version = 'Version 1.0.0',
    this.copyright = '© 2025 Fraya Taxi. Tous droits réservés.',
  });

  final String appName;
  final String version;
  final String copyright;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: context.colors.greyLight),
      ),
      child: Column(
        children: [
          Text(
            appName,
            style: AppTextStyles.h2.copyWith(color: const Color(0xFFB7882E)),
          ),
          const SizedBox(height: 8),
          Text(
            version,
            style: AppTextStyles.body.copyWith(color: context.colors.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            copyright,
            style: AppTextStyles.xs.copyWith(color: context.colors.textTertiary),
          ),
        ],
      ),
    );
  }
}

class AppSettingsDangerAction extends ConsumerWidget {
  const AppSettingsDangerAction({
    super.key,
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: context.colors.greyLight),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading) ...[
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 10),
            ],
            Text(
              isLoading ? 'Suppression...' : label,
              style: AppTextStyles.h4.copyWith(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.items,
  });

  final String title;
  final List<AppSettingsItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Text(
              title,
              style: AppTextStyles.body.copyWith(color: context.colors.textSecondary),
            ),
          ),
          for (final item in items)
            _SettingTile(
              icon: item.icon,
              iconColor: item.iconColor,
              title: item.title,
              value: item.value,
              onTap: item.onTap,
            ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.value,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: context.colors.border)),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.h4.copyWith(color: context.colors.textPrimary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (value != null) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  value!,
                  style: AppTextStyles.body.copyWith(color: context.colors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: context.colors.textTertiary),
          ],
        ),
      ),
    );
  }
}
