import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../data/repositories/booking_repository_impl.dart';
import '../../../../data/sources/remote/booking_remote_data_source.dart';
import '../../../../core/services/ride_tracking_share_service.dart';
import '../../../../domain/repositories/booking_repository.dart';
import '../../../../domain/usecases/passenger/calculate_ride_category_prices.dart';
import '../../../../domain/usecases/passenger/cancel_ride.dart';
import '../../../../domain/usecases/passenger/create_ride_share_link.dart';
import '../../../../domain/usecases/passenger/create_sos_alert.dart';
import '../../../../domain/usecases/passenger/get_active_ride.dart';
import '../../../../domain/usecases/passenger/get_ride_categories.dart';
import '../../../../domain/usecases/passenger/rate_ride.dart';
import '../../../../domain/usecases/passenger/report_ride_problem.dart';
import '../../../../domain/usecases/passenger/request_ride.dart';
import '../../../../domain/usecases/passenger/share_ride_tracking_message.dart';

final bookingRemoteDataSourceProvider = Provider<BookingRemoteDataSource>((
  ref,
) {
  return BookingRemoteDataSource();
});

final passengerBookingRepositoryProvider = Provider<BookingRepository>((ref) {
  final remoteDataSource = ref.watch(bookingRemoteDataSourceProvider);
  return BookingRepositoryImpl(remoteDataSource: remoteDataSource);
});

final getRideCategoriesUseCaseProvider = Provider<GetRideCategoriesUseCase>((
  ref,
) {
  final repository = ref.watch(passengerBookingRepositoryProvider);
  return GetRideCategoriesUseCase(repository);
});

final calculateRideCategoryPricesUseCaseProvider =
    Provider<CalculateRideCategoryPricesUseCase>((ref) {
      final repository = ref.watch(passengerBookingRepositoryProvider);
      return CalculateRideCategoryPricesUseCase(repository);
    });

final requestRideUseCaseProvider = Provider<RequestRideUseCase>((ref) {
  final repository = ref.watch(passengerBookingRepositoryProvider);
  return RequestRideUseCase(repository);
});

final getActiveRideUseCaseProvider = Provider<GetActiveRideUseCase>((ref) {
  final repository = ref.watch(passengerBookingRepositoryProvider);
  return GetActiveRideUseCase(repository);
});

final createRideShareLinkUseCaseProvider = Provider<CreateRideShareLinkUseCase>(
  (ref) {
    final repository = ref.watch(passengerBookingRepositoryProvider);
    return CreateRideShareLinkUseCase(repository);
  },
);

final cancelRideUseCaseProvider = Provider<CancelRideUseCase>((ref) {
  final repository = ref.watch(passengerBookingRepositoryProvider);
  return CancelRideUseCase(repository);
});

final rateRideUseCaseProvider = Provider<RateRideUseCase>((ref) {
  final repository = ref.watch(passengerBookingRepositoryProvider);
  return RateRideUseCase(repository);
});

final createSosAlertUseCaseProvider = Provider<CreateSosAlertUseCase>((ref) {
  final repository = ref.watch(passengerBookingRepositoryProvider);
  return CreateSosAlertUseCase(repository);
});

final reportRideProblemUseCaseProvider = Provider<ReportRideProblemUseCase>((
  ref,
) {
  final repository = ref.watch(passengerBookingRepositoryProvider);
  return ReportRideProblemUseCase(repository);
});

final rideTrackingShareServiceProvider = Provider<RideTrackingShareService>((
  ref,
) {
  return const RideTrackingShareService();
});

final shareRideTrackingMessageUseCaseProvider =
    Provider<ShareRideTrackingMessageUseCase>((ref) {
      final service = ref.watch(rideTrackingShareServiceProvider);
      return ShareRideTrackingMessageUseCase(service);
    });

/// Transporte le dernier message d'erreur du flux de reservation vers l'UI.
/// Remis a null apres affichage.
final bookingErrorProvider = StateProvider<String?>((ref) => null);

/// Nombre de tentatives de recherche de chauffeur effectuees.
final bookingRetryCountProvider = StateProvider<int>((ref) => 0);

/// Evenement UI emis apres une annulation demandee par le passager.
final bookingActiveRideCancelledHomeEventProvider = StateProvider<int>(
  (ref) => 0,
);

/// Evenement UI emis quand une course active est annulee a distance.
final bookingRemoteRideCancelledEventProvider = StateProvider<int>((ref) => 0);
