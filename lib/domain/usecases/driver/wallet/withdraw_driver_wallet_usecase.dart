library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../repositories/driver_wallet_repository.dart';
import '../../usecase.dart';
import '../rides/driver_ride_failure_mapper.dart';

class WithdrawDriverWalletParams {
  const WithdrawDriverWalletParams({
    required this.amount,
    this.walletId,
  });

  final double amount;
  final String? walletId;
}

class WithdrawDriverWalletUseCase
    extends UseCase<void, WithdrawDriverWalletParams> {
  WithdrawDriverWalletUseCase(this._repository);

  final DriverWalletRepository _repository;

  @override
  Future<Either<Failure, void>> call(WithdrawDriverWalletParams params) async {
    try {
      await _repository.withdrawWallet(
        amount: params.amount,
        walletId: params.walletId,
      );
      return const Right(null);
    } catch (error) {
      return left(mapDriverRideException(error));
    }
  }
}
