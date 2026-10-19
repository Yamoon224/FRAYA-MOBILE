import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/error/exceptions.dart';
import 'package:fraya_mobile/domain/models/driver_kyc_document_file.dart';
import 'package:fraya_mobile/domain/models/driver_vehicle_document_type.dart';
import 'package:fraya_mobile/domain/repositories/driver_vehicle_repository.dart';
import 'package:fraya_mobile/domain/usecases/driver/vehicle/request_driver_vehicle_secondary_range_usecase.dart';
import 'package:fraya_mobile/domain/usecases/driver/vehicle/update_driver_vehicle_secondary_range_usecase.dart';
import 'package:fraya_mobile/features/driver/vehicle/providers/driver_vehicle_ranges_provider.dart';

class _FakeRepository implements DriverVehicleRepository {
  String? updatedRange;
  bool updateCalled = false;
  String? requestedRange;
  Map<DriverVehicleDocumentType, DriverKycDocumentFile>? requestedPhotos;
  Object? failure;

  @override
  Future<Map<String, dynamic>> updateSecondaryRange({
    required int vehicleId,
    required String? secondaryRange,
  }) async {
    if (failure != null) throw failure!;
    updateCalled = true;
    updatedRange = secondaryRange;
    return {'id': vehicleId};
  }

  @override
  Future<Map<String, dynamic>> requestSecondaryRange({
    required int vehicleId,
    required String secondaryRange,
    required Map<DriverVehicleDocumentType, DriverKycDocumentFile> photos,
  }) async {
    if (failure != null) throw failure!;
    requestedRange = secondaryRange;
    requestedPhotos = photos;
    return {'id': 1};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

DriverKycDocumentFile _photo(String name) => DriverKycDocumentFile.fromPath(
  path: '/tmp/$name.jpg',
  fileName: '$name.jpg',
  source: DriverKycDocumentSource.galleryImage,
)!;

DriverVehicleRangesNotifier _build(
  _FakeRepository repository, {
  String primary = 'GLADIATEUR',
  String? secondary,
}) {
  return DriverVehicleRangesNotifier(
    args: DriverVehicleRangesArgs(
      vehicleId: 5,
      primaryRange: primary,
      currentSecondaryRange: secondary,
    ),
    updateUseCase: UpdateDriverVehicleSecondaryRangeUseCase(repository),
    requestUseCase: RequestDriverVehicleSecondaryRangeUseCase(repository),
  );
}

void main() {
  group('DriverVehicleRangesNotifier', () {
    test('ne propose aucun envoi tant que rien ne change', () {
      final notifier = _build(_FakeRepository(), secondary: 'MAGIC');

      expect(notifier.state.hasChange, isFalse);
      expect(notifier.state.canSubmit, isFalse);
    });

    test('retire la seconde gamme immédiatement (libre-service)', () async {
      final repository = _FakeRepository();
      final notifier = _build(repository, secondary: 'MAGIC');

      notifier.selectSecondaryRange(null);
      expect(notifier.state.requiresReview, isFalse);
      expect(notifier.state.canSubmit, isTrue);
      await notifier.submit();

      expect(repository.updateCalled, isTrue);
      expect(repository.updatedRange, isNull);
      expect(notifier.state.outcome, DriverVehicleRangesOutcome.updated);
    });

    test('remplace par une gamme déjà couverte sans photos', () async {
      final repository = _FakeRepository();
      final notifier = _build(repository);

      notifier.selectSecondaryRange('magic');
      expect(notifier.state.requiresReview, isFalse);
      await notifier.submit();

      expect(repository.updatedRange, 'MAGIC');
      expect(repository.requestedRange, isNull);
    });

    test('une gamme supérieure exige les cinq photos avant l\'envoi', () async {
      final repository = _FakeRepository();
      final notifier = _build(repository);

      notifier.selectSecondaryRange('ELITE');
      expect(notifier.state.requiresReview, isTrue);
      expect(notifier.state.canSubmit, isFalse);

      for (final type in vehicleRangePhotoTypes.take(4)) {
        notifier.setPhoto(type, _photo(type.name));
      }
      expect(notifier.state.canSubmit, isFalse);

      notifier.setPhoto(vehicleRangePhotoTypes.last, _photo('last'));
      expect(notifier.state.canSubmit, isTrue);

      await notifier.submit();

      expect(repository.requestedRange, 'ELITE');
      expect(repository.requestedPhotos?.keys.toSet(), vehicleRangePhotoTypes.toSet());
      expect(repository.updateCalled, isFalse);
      expect(notifier.state.outcome, DriverVehicleRangesOutcome.requested);
    });

    test('ignore les photos qui ne font pas partie des cinq exigées', () {
      final notifier = _build(_FakeRepository());

      notifier.setPhoto(DriverVehicleDocumentType.insuranceCertificate, _photo('assurance'));

      expect(notifier.state.photos, isEmpty);
    });

    test('refuse la gamme principale comme seconde gamme', () {
      final notifier = _build(_FakeRepository());

      notifier.selectSecondaryRange('GLADIATEUR');

      expect(notifier.state.selectedSecondaryRange, isNull);
    });

    test('affiche l\'erreur du serveur et ne conclut pas en cas d\'échec', () async {
      final repository = _FakeRepository()
        ..failure = const ServerException(
          message: 'Cette gamme dépasse celle de votre véhicule',
          statusCode: 400,
        );
      final notifier = _build(repository, secondary: 'MAGIC');

      notifier.selectSecondaryRange(null);
      await notifier.submit();

      expect(notifier.state.errorMessage, contains('dépasse'));
      expect(notifier.state.outcome, isNull);
      expect(notifier.state.isSubmitting, isFalse);
    });
  });
}
