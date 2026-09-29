library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/driver_document_preparation_service.dart';
import '../../../../data/repositories/driver_kyc_repository_impl.dart';
import '../../../../data/sources/remote/driver_kyc_remote_data_source.dart';
import '../../../../domain/repositories/driver_kyc_repository.dart';
import '../../../../domain/usecases/driver/kyc/get_driver_kyc_by_sid_user_usecase.dart';
import '../../../../domain/usecases/driver/kyc/submit_driver_kyc_usecase.dart';
import 'driver_kyc_document_picker.dart';

final driverDocumentPreparationServiceProvider =
    Provider<DriverDocumentPreparationService>((ref) {
      return DriverDocumentPreparationService();
    });

final driverKycRemoteDataSourceProvider = Provider<DriverKycRemoteDataSource>((
  ref,
) {
  return DriverKycRemoteDataSource();
});

final driverKycRepositoryProvider = Provider<DriverKycRepository>((ref) {
  final remoteDataSource = ref.watch(driverKycRemoteDataSourceProvider);
  final preparationService = ref.watch(
    driverDocumentPreparationServiceProvider,
  );
  return DriverKycRepositoryImpl(
    remoteDataSource: remoteDataSource,
    preparationService: preparationService,
  );
});

final submitDriverKycUseCaseProvider = Provider<SubmitDriverKycUseCase>((ref) {
  final repository = ref.watch(driverKycRepositoryProvider);
  return SubmitDriverKycUseCase(repository);
});

final getDriverKycBySidUserUseCaseProvider =
    Provider<GetDriverKycBySidUserUseCase>((ref) {
      final repository = ref.watch(driverKycRepositoryProvider);
      return GetDriverKycBySidUserUseCase(repository);
    });

final driverKycDocumentPickerProvider = Provider<DriverKycDocumentPicker>((
  ref,
) {
  return DriverKycDocumentPicker();
});
