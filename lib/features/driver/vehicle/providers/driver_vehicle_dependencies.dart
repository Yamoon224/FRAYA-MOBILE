library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/repositories/driver_vehicle_repository_impl.dart';
import '../../../../data/sources/remote/driver_vehicle_remote_data_source.dart';
import '../../../../domain/repositories/driver_vehicle_repository.dart';
import '../../../../domain/usecases/driver/vehicle/submit_driver_vehicle_usecase.dart';
import '../../../../domain/usecases/driver/vehicle/update_driver_vehicle_usecase.dart';
import '../../kyc/providers/driver_kyc_dependencies.dart';

final driverVehicleRemoteDataSourceProvider =
    Provider<DriverVehicleRemoteDataSource>((ref) {
      return DriverVehicleRemoteDataSource();
    });

final driverVehicleRepositoryProvider = Provider<DriverVehicleRepository>((
  ref,
) {
  final remoteDataSource = ref.watch(driverVehicleRemoteDataSourceProvider);
  final preparationService = ref.watch(
    driverDocumentPreparationServiceProvider,
  );
  return DriverVehicleRepositoryImpl(
    remoteDataSource: remoteDataSource,
    preparationService: preparationService,
  );
});

final submitDriverVehicleUseCaseProvider = Provider<SubmitDriverVehicleUseCase>(
  (ref) {
    final repository = ref.watch(driverVehicleRepositoryProvider);
    return SubmitDriverVehicleUseCase(repository);
  },
);

final updateDriverVehicleUseCaseProvider = Provider<UpdateDriverVehicleUseCase>(
  (ref) {
    final repository = ref.watch(driverVehicleRepositoryProvider);
    return UpdateDriverVehicleUseCase(repository);
  },
);
