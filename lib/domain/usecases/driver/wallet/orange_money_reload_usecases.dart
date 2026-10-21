library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../models/orange_money_payment.dart';
import '../../../repositories/driver_wallet_repository.dart';
import '../../usecase.dart';
import '../rides/driver_ride_failure_mapper.dart';

class InitializeOrangeMoneyReloadParams {
  const InitializeOrangeMoneyReloadParams({required this.amount});

  final double amount;
}

class InitializeOrangeMoneyReloadUseCase
    extends UseCase<OrangeMoneyPayment, InitializeOrangeMoneyReloadParams> {
  InitializeOrangeMoneyReloadUseCase(this._repository);

  final DriverWalletRepository _repository;

  @override
  Future<Either<Failure, OrangeMoneyPayment>> call(
    InitializeOrangeMoneyReloadParams params,
  ) async {
    try {
      return Right(
        await _repository.initializeOrangeMoneyReload(amount: params.amount),
      );
    } catch (error) {
      return left(mapDriverRideException(error));
    }
  }
}

class VerifyOrangeMoneyReloadParams {
  const VerifyOrangeMoneyReloadParams({required this.reference});

  final String reference;
}

class VerifyOrangeMoneyReloadUseCase
    extends UseCase<OrangeMoneyPaymentStatus, VerifyOrangeMoneyReloadParams> {
  VerifyOrangeMoneyReloadUseCase(this._repository);

  final DriverWalletRepository _repository;

  @override
  Future<Either<Failure, OrangeMoneyPaymentStatus>> call(
    VerifyOrangeMoneyReloadParams params,
  ) async {
    try {
      return Right(await _repository.verifyOrangeMoneyReload(params.reference));
    } catch (error) {
      return left(mapDriverRideException(error));
    }
  }
}
