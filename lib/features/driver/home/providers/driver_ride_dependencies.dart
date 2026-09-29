import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/repositories/driver_ride_repository_impl.dart';
import '../../../../data/sources/remote/driver_ride_remote_data_source.dart';
import '../../../../domain/repositories/driver_ride_repository.dart';
import '../../../../domain/usecases/driver/rides/accept_driver_ride.dart';
import '../../../../domain/usecases/driver/rides/cancel_driver_ride.dart';
import '../../../../domain/usecases/driver/rides/complete_driver_ride.dart';
import '../../../../domain/usecases/driver/rides/fetch_available_driver_rides.dart';
import '../../../../domain/usecases/driver/rides/get_driver_active_ride.dart';
import '../../../../domain/usecases/driver/rides/get_driver_history_rides.dart';
import '../../../../domain/usecases/driver/rides/mark_driver_ride_arrived.dart';
import '../../../../domain/usecases/driver/rides/send_driver_location.dart';
import '../../../../domain/usecases/driver/rides/start_driver_ride.dart';
import '../../../../domain/usecases/passenger/rate_ride.dart';
import '../../../passenger/booking/providers/booking_dependencies.dart';

final driverRideRemoteDataSourceProvider = Provider<DriverRideRemoteDataSource>(
  (ref) {
    return DriverRideRemoteDataSource();
  },
);

final driverRideRepositoryProvider = Provider<DriverRideRepository>((ref) {
  final remoteDataSource = ref.watch(driverRideRemoteDataSourceProvider);
  return DriverRideRepositoryImpl(remoteDataSource: remoteDataSource);
});

final fetchAvailableDriverRidesUseCaseProvider =
    Provider<FetchAvailableDriverRidesUseCase>((ref) {
      final repository = ref.watch(driverRideRepositoryProvider);
      return FetchAvailableDriverRidesUseCase(repository);
    });

final getDriverActiveRideUseCaseProvider = Provider<GetDriverActiveRideUseCase>(
  (ref) {
    final repository = ref.watch(driverRideRepositoryProvider);
    return GetDriverActiveRideUseCase(repository);
  },
);

final getDriverHistoryRidesUseCaseProvider =
    Provider<GetDriverHistoryRidesUseCase>((ref) {
      final repository = ref.watch(driverRideRepositoryProvider);
      return GetDriverHistoryRidesUseCase(repository);
    });

final acceptDriverRideUseCaseProvider = Provider<AcceptDriverRideUseCase>((
  ref,
) {
  final repository = ref.watch(driverRideRepositoryProvider);
  return AcceptDriverRideUseCase(repository);
});

final markDriverRideArrivedUseCaseProvider =
    Provider<MarkDriverRideArrivedUseCase>((ref) {
      final repository = ref.watch(driverRideRepositoryProvider);
      return MarkDriverRideArrivedUseCase(repository);
    });

final startDriverRideUseCaseProvider = Provider<StartDriverRideUseCase>((ref) {
  final repository = ref.watch(driverRideRepositoryProvider);
  return StartDriverRideUseCase(repository);
});

final completeDriverRideUseCaseProvider = Provider<CompleteDriverRideUseCase>((
  ref,
) {
  final repository = ref.watch(driverRideRepositoryProvider);
  return CompleteDriverRideUseCase(repository);
});

final cancelDriverRideUseCaseProvider = Provider<CancelDriverRideUseCase>((
  ref,
) {
  final repository = ref.watch(driverRideRepositoryProvider);
  return CancelDriverRideUseCase(repository);
});

final sendDriverLocationUseCaseProvider = Provider<SendDriverLocationUseCase>((
  ref,
) {
  final repository = ref.watch(driverRideRepositoryProvider);
  return SendDriverLocationUseCase(repository);
});

final sendDriverAvailabilityLocationUseCaseProvider =
    Provider<SendDriverAvailabilityLocationUseCase>((ref) {
      final repository = ref.watch(driverRideRepositoryProvider);
      return SendDriverAvailabilityLocationUseCase(repository);
    });

final driverRateRideUseCaseProvider = Provider<RateRideUseCase>((ref) {
  final repository = ref.watch(passengerBookingRepositoryProvider);
  return RateRideUseCase(repository);
});
