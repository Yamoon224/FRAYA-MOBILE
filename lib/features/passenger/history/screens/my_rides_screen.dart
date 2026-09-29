import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../providers/history_filter_provider.dart';
import '../providers/history_provider.dart';
import '../widgets/history_filter_bar.dart';
import '../widgets/history_stats_header.dart';
import '../widgets/rides_list.dart';

class MyRidesScreen extends ConsumerStatefulWidget {
  const MyRidesScreen({super.key});

  @override
  ConsumerState<MyRidesScreen> createState() => _MyRidesScreenState();
}

class _MyRidesScreenState extends ConsumerState<MyRidesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _hardRefreshHistory() async {
    if (_tabController.index != 0) {
      _tabController.animateTo(0);
    }
    ref.invalidate(historyFilterControllerProvider);
    ref.invalidate(rideHistoryProvider);
    await ref.read(rideHistoryProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(rideHistoryProvider);
    final showLoading = historyAsync.isLoading && !historyAsync.hasValue;
    final showError = historyAsync.hasError && !historyAsync.hasValue;
    final recentRides = ref.watch(recentRidesProvider);
    final filteredRides = ref.watch(filteredRidesProvider);
    final errorMessage = _toErrorMessage(historyAsync.error);
    final appBarColor = context.colors.surface;
    final titleColor = context.colors.textPrimary;
    final secondaryTextColor = context.colors.textSecondary;
    final dividerColor = context.colors.greyLight;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: titleColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Mes courses',
          style: AppTextStyles.h2.copyWith(color: titleColor),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          const HistoryStatsHeader(),
          TabBar(
            controller: _tabController,
            labelStyle: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: AppTextStyles.body,
            labelColor: AppColors.primaryDark,
            unselectedLabelColor: secondaryTextColor,
            indicatorColor: AppColors.primaryDark,
            indicatorWeight: 2,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: const [
              Tab(text: 'Recentes'),
              Tab(text: 'Toutes'),
            ],
          ),
          Divider(height: 1, color: dividerColor),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                showError
                    ? _HistoryErrorView(
                        message: errorMessage,
                        onRefresh: _hardRefreshHistory,
                      )
                    : RefreshIndicator(
                        onRefresh: _hardRefreshHistory,
                        child: RidesList(
                          rides: recentRides,
                          isLoading: showLoading,
                          emptyMessage: 'Aucune course recente',
                          showFooter: recentRides.isNotEmpty,
                          onFooterTap: () => _tabController.animateTo(1),
                        ),
                      ),
                showError
                    ? _HistoryErrorView(
                        message: errorMessage,
                        onRefresh: _hardRefreshHistory,
                      )
                    : Column(
                        children: [
                          const HistoryFilterBar(),
                          Expanded(
                            child: RefreshIndicator(
                              onRefresh: _hardRefreshHistory,
                              child: RidesList(
                                rides: filteredRides,
                                isLoading: showLoading,
                                emptyMessage: 'Aucune course sur cette période',
                              ),
                            ),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _toErrorMessage(Object? error) {
    final raw = error?.toString().trim() ?? '';
    for (final prefix in const [
      'NetworkException: ',
      'AuthException: ',
      'ValidationException: ',
      'CacheException: ',
      'ServerException(null): ',
    ]) {
      if (raw.startsWith(prefix)) {
        return raw.substring(prefix.length).trim();
      }
    }
    if (raw.startsWith('ServerException(')) {
      final separator = raw.indexOf(': ');
      if (separator != -1) {
        return raw.substring(separator + 2).trim();
      }
    }
    if (raw.startsWith('Exception: ')) {
      return raw.substring('Exception: '.length).trim();
    }
    if (raw.startsWith('Bad state: ')) {
      return raw.substring('Bad state: '.length).trim();
    }
    if (raw.isNotEmpty) {
      return raw;
    }
    return 'Impossible de charger vos courses pour le moment.';
  }
}

class _HistoryErrorView extends StatelessWidget {
  const _HistoryErrorView({required this.message, required this.onRefresh});

  final String message;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingLg,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history_toggle_off_rounded,
                      size: 56,
                      color: context.colors.textSecondary,
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    Text(
                      'Impossible de charger vos courses.',
                      style: AppTextStyles.h3,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    Text(
                      message,
                      style: AppTextStyles.body.copyWith(
                        color: context.colors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.spacingLg),
                    ElevatedButton.icon(
                      onPressed: onRefresh,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Réessayer'),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    Text(
                      'Tirez vers le bas pour actualiser.',
                      style: AppTextStyles.small.copyWith(
                        color: context.colors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
