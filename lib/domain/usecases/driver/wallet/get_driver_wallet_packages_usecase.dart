library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../models/driver_wallet_package.dart';
import '../../../repositories/driver_wallet_repository.dart';
import '../../usecase.dart';
import '../rides/driver_ride_failure_mapper.dart';

class GetDriverWalletPackagesUseCase
    extends UseCase<List<DriverWalletPackage>, NoParams> {
  GetDriverWalletPackagesUseCase(this._repository);

  final DriverWalletRepository _repository;

  @override
  Future<Either<Failure, List<DriverWalletPackage>>> call(
    NoParams params,
  ) async {
    try {
      final packages = await _repository.fetchPackages();
      return right(packages);
    } catch (error) {
      return left(mapDriverRideException(error));
    }
  }
}
