library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../models/driver_wallet_overview.dart';
import '../../../repositories/driver_wallet_repository.dart';
import '../../usecase.dart';
import '../rides/driver_ride_failure_mapper.dart';

class GetDriverWalletOverviewUseCase
    extends UseCase<DriverWalletOverview, NoParams> {
  GetDriverWalletOverviewUseCase(this._repository);

  final DriverWalletRepository _repository;

  @override
  Future<Either<Failure, DriverWalletOverview>> call(NoParams params) async {
    try {
      final overview = await _repository.fetchWalletOverview();
      return right(overview);
    } catch (error) {
      return left(mapDriverRideException(error));
    }
  }
}
