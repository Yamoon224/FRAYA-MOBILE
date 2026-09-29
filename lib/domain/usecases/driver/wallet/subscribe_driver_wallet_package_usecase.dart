library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../models/driver_wallet_package_subscription_result.dart';
import '../../../repositories/driver_wallet_repository.dart';
import '../../usecase.dart';
import '../rides/driver_ride_failure_mapper.dart';

class SubscribeDriverWalletPackageParams {
  const SubscribeDriverWalletPackageParams({
    required this.sidUserId,
    required this.packageId,
  });

  final int sidUserId;
  final int packageId;
}

class SubscribeDriverWalletPackageUseCase
    extends
        UseCase<
          DriverWalletPackageSubscriptionResult,
          SubscribeDriverWalletPackageParams
        > {
  SubscribeDriverWalletPackageUseCase(this._repository);

  final DriverWalletRepository _repository;

  @override
  Future<Either<Failure, DriverWalletPackageSubscriptionResult>> call(
    SubscribeDriverWalletPackageParams params,
  ) async {
    try {
      final result = await _repository.subscribeToPackage(
        sidUserId: params.sidUserId,
        packageId: params.packageId,
      );
      return right(result);
    } catch (error) {
      return left(mapDriverRideException(error));
    }
  }
}
