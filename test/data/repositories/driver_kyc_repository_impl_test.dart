import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/error/exceptions.dart';
import 'package:fraya_mobile/data/repositories/driver_kyc_repository_impl.dart';
import 'package:fraya_mobile/data/sources/remote/driver_kyc_remote_data_source.dart';
import 'package:fraya_mobile/domain/models/driver_kyc_document_file.dart';
import 'package:fraya_mobile/domain/models/driver_kyc_document_type.dart';
import 'package:fraya_mobile/domain/models/driver_kyc_submission.dart';

import '../../support/driver_document_preparation_test_double.dart';

class _RecordingKycRemoteDataSource extends DriverKycRemoteDataSource {
  _RecordingKycRemoteDataSource() : super(dio: Dio());

  DriverKycSubmission? submission;

  @override
  Future<Map<String, dynamic>> submitKyc({
    required int userId,
    required DriverKycSubmission submission,
  }) async {
    this.submission = submission;
    return {'id': 10};
  }
}

void main() {
  test('prepares every KYC document before delegating submission', () async {
    final remote = _RecordingKycRemoteDataSource();
    final preparation = PassthroughDriverDocumentPreparationService();
    final repository = DriverKycRepositoryImpl(
      remoteDataSource: remote,
      preparationService: preparation,
    );
    final submission = DriverKycSubmission(
      documents: {
        DriverKycDocumentType.photoFrontPermis: _image('/tmp/front.jpg'),
        DriverKycDocumentType.photoBackPermis: _image('/tmp/back.jpg'),
      },
    );

    await repository.submitKyc(userId: 7, submission: submission);

    expect(preparation.prepareCalls, 2);
    expect(remote.submission?.documents.keys, submission.documents.keys);
  });

  test('does not call the API when document preparation fails', () async {
    final remote = _RecordingKycRemoteDataSource();
    final preparation = PassthroughDriverDocumentPreparationService()
      ..error = const DocumentPreparationException(message: 'Document lourd');
    final repository = DriverKycRepositoryImpl(
      remoteDataSource: remote,
      preparationService: preparation,
    );
    final submission = DriverKycSubmission(
      documents: {
        DriverKycDocumentType.photoFrontPermis: _image('/tmp/front.jpg'),
      },
    );

    await expectLater(
      repository.submitKyc(userId: 7, submission: submission),
      throwsA(isA<DocumentPreparationException>()),
    );
    expect(remote.submission, isNull);
  });
}

DriverKycDocumentFile _image(String path) {
  return DriverKycDocumentFile.fromPath(
    path: path,
    fileName: path.split('/').last,
    source: DriverKycDocumentSource.galleryImage,
  )!;
}
