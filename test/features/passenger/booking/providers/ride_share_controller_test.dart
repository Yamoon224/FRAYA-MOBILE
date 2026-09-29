import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fraya_mobile/core/error/exceptions.dart';
import 'package:fraya_mobile/core/services/ride_tracking_share_service.dart';
import 'package:fraya_mobile/domain/models/active_ride.dart';
import 'package:fraya_mobile/domain/models/ride_share_link.dart';
import 'package:fraya_mobile/domain/models/ride_status.dart';
import 'package:fraya_mobile/domain/repositories/booking_repository.dart';
import 'package:fraya_mobile/domain/usecases/passenger/create_ride_share_link.dart';
import 'package:fraya_mobile/domain/usecases/passenger/share_ride_tracking_message.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/active_ride_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/booking_dependencies.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/ride_share_controller.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  test('shareActiveRide creates the link and returns success feedback', () async {
    final repository = _FakeBookingRepository();
    final shareService = _FakeRideTrackingShareService();
    final container = ProviderContainer(
      overrides: [
        activeRideControllerProvider.overrideWithValue(_ride(RideStatus.arrived)),
        createRideShareLinkUseCaseProvider.overrideWithValue(
          CreateRideShareLinkUseCase(repository),
        ),
        shareRideTrackingMessageUseCaseProvider.overrideWithValue(
          ShareRideTrackingMessageUseCase(shareService),
        ),
      ],
    );
    addTearDown(container.dispose);

    final feedback = await container
        .read(rideShareControllerProvider.notifier)
        .shareActiveRide();

    expect(repository.lastRideId, 'ride-77');
    expect(repository.lastExpiresIn, 60);
    expect(shareService.lastUrl, repository.rideShareLink.url);
    expect(feedback?.message, 'Partage reussi.');
    expect(feedback?.type, RideShareFeedbackType.success);
  });

  test('shareActiveRide returns fixed error when link generation fails', () async {
    final repository = _FakeBookingRepository(shouldThrowOnCreateLink: true);
    final container = ProviderContainer(
      overrides: [
        activeRideControllerProvider.overrideWithValue(
          _ride(RideStatus.inProgress),
        ),
        createRideShareLinkUseCaseProvider.overrideWithValue(
          CreateRideShareLinkUseCase(repository),
        ),
      ],
    );
    addTearDown(container.dispose);

    final feedback = await container
        .read(rideShareControllerProvider.notifier)
        .shareActiveRide();

    expect(feedback?.message, 'Impossible de generer le lien de suivi.');
    expect(feedback?.type, RideShareFeedbackType.error);
    expect(
      container.read(rideShareControllerProvider).errorMessage,
      'Impossible de generer le lien de suivi.',
    );
  });

  test('shareActiveRide returns info feedback when user dismisses sharing', () async {
    final repository = _FakeBookingRepository();
    final shareService = _FakeRideTrackingShareService(
      result: RideTrackingShareStatus.dismissed,
    );
    final container = ProviderContainer(
      overrides: [
        activeRideControllerProvider.overrideWithValue(_ride(RideStatus.arrived)),
        createRideShareLinkUseCaseProvider.overrideWithValue(
          CreateRideShareLinkUseCase(repository),
        ),
        shareRideTrackingMessageUseCaseProvider.overrideWithValue(
          ShareRideTrackingMessageUseCase(shareService),
        ),
      ],
    );
    addTearDown(container.dispose);

    final feedback = await container
        .read(rideShareControllerProvider.notifier)
        .shareActiveRide();

    expect(feedback?.message, 'Partage annule.');
    expect(feedback?.type, RideShareFeedbackType.info);
  });

  test('shareActiveRide blocks concurrent submissions', () async {
    final repository = _FakeBookingRepository();
    final shareService = _FakeRideTrackingShareService(waitForCompletion: true);
    final container = ProviderContainer(
      overrides: [
        activeRideControllerProvider.overrideWithValue(_ride(RideStatus.arrived)),
        createRideShareLinkUseCaseProvider.overrideWithValue(
          CreateRideShareLinkUseCase(repository),
        ),
        shareRideTrackingMessageUseCaseProvider.overrideWithValue(
          ShareRideTrackingMessageUseCase(shareService),
        ),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(rideShareControllerProvider.notifier);
    final firstCall = controller.shareActiveRide();
    final secondCall = controller.shareActiveRide();
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(await secondCall, isNull);
    expect(shareService.callCount, 1);

    shareService.completePendingRequest();
    final feedback = await firstCall;
    expect(feedback?.message, 'Partage reussi.');
  });
}

class _FakeBookingRepository implements BookingRepository {
  _FakeBookingRepository({this.shouldThrowOnCreateLink = false});

  final bool shouldThrowOnCreateLink;
  final rideShareLink = const RideShareLink(
    token: 'fraya-token',
    url: 'https://manager.frayataxi.ci/ride/tracking/fraya-token',
    expiresAt: null,
    isValid: true,
  );
  String? lastRideId;
  int? lastExpiresIn;

  @override
  Future<RideShareLink> createRideShareLink({
    required String rideId,
    int expiresIn = 60,
  }) async {
    if (shouldThrowOnCreateLink) {
      throw const ServerException(message: 'Erreur test');
    }
    lastRideId = rideId;
    lastExpiresIn = expiresIn;
    return rideShareLink;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRideTrackingShareService extends RideTrackingShareService {
  _FakeRideTrackingShareService({
    this.result = RideTrackingShareStatus.success,
    this.waitForCompletion = false,
  });

  final RideTrackingShareStatus result;
  final bool waitForCompletion;
  int callCount = 0;
  String? lastUrl;
  Completer<void>? _pendingCompleter;

  @override
  Future<RideTrackingShareStatus> shareTrackingLink(String url) async {
    callCount++;
    lastUrl = url;
    if (waitForCompletion) {
      _pendingCompleter = Completer<void>();
      await _pendingCompleter!.future;
    }
    return result;
  }

  void completePendingRequest() {
    _pendingCompleter?.complete();
    _pendingCompleter = null;
  }
}

ActiveRide _ride(RideStatus status) {
  return ActiveRide(
    rideId: 'ride-77',
    driverName: 'Jean',
    driverPhoto: 'assets/images/driver_placeholder.png',
    driverRating: 4.8,
    carModel: 'Toyota',
    carPlate: 'AA-123-BB',
    destinationAddress: 'Plateau',
    driverLocation: const LatLng(5.35, -4.01),
    destinationLocation: const LatLng(5.32, -4.00),
    status: status,
    estimatedPrice: 3000,
  );
}
