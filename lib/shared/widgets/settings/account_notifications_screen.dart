import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/extensions.dart';
import '../fraya_skeleton.dart';

class AccountNotificationsScreen extends StatelessWidget {
  const AccountNotificationsScreen({
    super.key,
    required this.asyncNotifications,
    required this.isSubmitting,
    required this.onRefresh,
    required this.onMarkAsRead,
    this.header,
    this.title = 'Notifications',
  });

  final AsyncValue<List<Map<String, dynamic>>> asyncNotifications;
  final bool isSubmitting;
  final Future<void> Function() onRefresh;
  final Future<void> Function(List<int> ids) onMarkAsRead;
  final Widget? header;
  final String title;

  @override
  Widget build(BuildContext context) {
    final tileColor = context.colors.surfaceElevated;
    final textColor = context.colors.textPrimary;
    final secondaryTextColor = context.colors.textSecondary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          title,
          style: AppTextStyles.h4.copyWith(
            color: textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: onRefresh,
        child: asyncNotifications.when(
          loading: () => _NotificationsLoadingState(header: header),
          error: (_, _) => CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (header != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.spacingLg,
                      AppTheme.spacingLg,
                      AppTheme.spacingLg,
                      0,
                    ),
                    child: header,
                  ),
                ),
              SliverFillRemaining(
                child: Center(
                  child: Text(
                    'Impossible de charger les notifications.',
                    style: AppTextStyles.body.copyWith(
                      color: secondaryTextColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
          data: (items) {
            if (items.isEmpty) {
              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  if (header != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppTheme.spacingLg,
                          AppTheme.spacingLg,
                          AppTheme.spacingLg,
                          0,
                        ),
                        child: header,
                      ),
                    ),
                  SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'Aucune notification pour le moment.',
                        style: AppTextStyles.body.copyWith(
                          color: secondaryTextColor,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              itemBuilder: (context, index) {
                if (header != null && index == 0) return header!;
                final item = items[_resolveItemIndex(index)];
                final title = _pickText(item, const [
                  'title',
                  'subject',
                  'type',
                ], 'Notification');
                final body = _pickText(item, const [
                  'message',
                  'body',
                  'content',
                ], '');
                final id = _pickId(item);
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  tileColor: tileColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  title: Text(
                    title,
                    style: AppTextStyles.body.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: body.isEmpty
                      ? null
                      : Text(
                          body,
                          style: AppTextStyles.small.copyWith(
                            color: secondaryTextColor,
                          ),
                        ),
                  trailing: IconButton(
                    icon: isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.done_all_rounded),
                    onPressed: id == null || isSubmitting
                        ? null
                        : () => onMarkAsRead(<int>[id]),
                  ),
                );
              },
              separatorBuilder: (_, index) {
                final spacing = header != null && index == 0
                    ? AppTheme.spacingLg
                    : 10.0;
                return SizedBox(height: spacing);
              },
              itemCount: items.length + (header == null ? 0 : 1),
            );
          },
        ),
      ),
    );
  }

  static String _pickText(
    Map<String, dynamic> source,
    List<String> keys,
    String fallback,
  ) {
    for (final key in keys) {
      final value = source[key];
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }
    return fallback;
  }

  static int? _pickId(Map<String, dynamic> source) {
    final raw = source['id'] ?? source['notificationId'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '');
  }

  int _resolveItemIndex(int index) {
    if (header == null) return index;
    return index - 1;
  }
}

class _NotificationsLoadingState extends StatelessWidget {
  const _NotificationsLoadingState({this.header});

  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final tileColor = context.colors.surfaceElevated;

    return ListView.separated(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      itemBuilder: (_, index) {
        if (header != null && index == 0) return header!;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: tileColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: const Row(
            children: [
              FrayaSkeleton(height: 18, width: 18, borderRadius: 9),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonText(width: 140),
                    SizedBox(height: 8),
                    SkeletonText(width: 200, height: 10),
                  ],
                ),
              ),
              SizedBox(width: 12),
              FrayaSkeleton(height: 20, width: 20, borderRadius: 10),
            ],
          ),
        );
      },
      separatorBuilder: (_, index) {
        final spacing = header != null && index == 0 ? AppTheme.spacingLg : 10;
        return SizedBox(height: spacing.toDouble());
      },
      itemCount: 6 + (header == null ? 0 : 1),
    );
  }
}
