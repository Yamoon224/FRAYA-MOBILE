library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../models/driver_wallet_reload_result.dart';
import '../../../repositories/driver_wallet_repository.dart';
import '../../usecase.dart';
import '../rides/driver_ride_failure_mapper.dart';

class ReloadDriverWalletParams {
  const ReloadDriverWalletParams({required this.amount, this.walletId});

  final double amount;
  final String? walletId;
}

class ReloadDriverWalletUseCase
    extends UseCase<DriverWalletReloadResult, ReloadDriverWalletParams> {
  ReloadDriverWalletUseCase(this._repository);

  final DriverWalletRepository _repository;

  @override
  Future<Either<Failure, DriverWalletReloadResult>> call(
    ReloadDriverWalletParams params,
  ) async {
    try {
      final result = await _repository.reloadWallet(
        amount: params.amount,
        walletId: params.walletId,
      );
      return Right(result);
    } catch (error) {
      return left(mapDriverRideException(error));
    }
  }
}
