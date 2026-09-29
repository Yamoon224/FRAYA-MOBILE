import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../../core/services/ride_tracking_share_service.dart';
import '../usecase.dart';

class ShareRideTrackingMessageParams {
  const ShareRideTrackingMessageParams({required this.url});

  final String url;
}

class ShareRideTrackingMessageUseCase
    extends UseCase<RideTrackingShareStatus, ShareRideTrackingMessageParams> {
  ShareRideTrackingMessageUseCase(this._shareService);

  final RideTrackingShareService _shareService;

  @override
  Future<Either<Failure, RideTrackingShareStatus>> call(
    ShareRideTrackingMessageParams params,
  ) async {
    try {
      final result = await _shareService.shareTrackingLink(params.url);
      return Right(result);
    } catch (_) {
      return const Left(
        ServerFailure(
          message: 'Impossible de partager la course pour le moment.',
        ),
      );
    }
  }
}
