library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/repositories/driver_onboarding_draft_repository_impl.dart';
import '../../../../data/sources/local/driver_onboarding_draft_local_data_source.dart';
import '../../../../domain/repositories/driver_onboarding_draft_repository.dart';

final driverOnboardingDraftLocalDataSourceProvider =
    Provider<DriverOnboardingDraftLocalDataSource>((ref) {
      return DriverOnboardingDraftLocalDataSource();
    });

final driverOnboardingDraftRepositoryProvider =
    Provider<DriverOnboardingDraftRepository>((ref) {
      final localDataSource = ref.watch(
        driverOnboardingDraftLocalDataSourceProvider,
      );
      return DriverOnboardingDraftRepositoryImpl(
        localDataSource: localDataSource,
      );
    });
