library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../data/repositories/driver_wallet_repository_impl.dart';
import '../../../../../data/sources/remote/driver_wallet_remote_data_source.dart';
import '../../../../../domain/models/driver_ride.dart';
import '../../../../../domain/repositories/driver_wallet_repository.dart';
import '../../../../../domain/usecases/driver/wallet/get_driver_wallet_packages_usecase.dart';
import '../../../../../domain/usecases/driver/wallet/get_driver_wallet_overview_usecase.dart';
import '../../../../../domain/usecases/driver/wallet/reload_driver_wallet_usecase.dart';
import '../../../../../domain/usecases/driver/wallet/subscribe_driver_wallet_package_usecase.dart';
import '../../../../../domain/usecases/driver/wallet/withdraw_driver_wallet_usecase.dart';
import '../../auth/providers/driver_auth_provider.dart';

final driverProfileWalletInfoProvider =
    Provider<({String? walletId, double? solde})>((ref) {
      final userData = ref.watch(driverAuthProvider).userData;
      if (userData == null) return (walletId: null, solde: null);
      final wallets = userData['wallets'];
      if (wallets is! List || wallets.isEmpty) {
        return (walletId: null, solde: null);
      }
      final first = wallets.first;
      if (first is! Map) return (walletId: null, solde: null);
      return (
        walletId: first['walletId']?.toString(),
        solde: (first['solde'] as num?)?.toDouble(),
      );
    });

final driverWalletCompletedRidesProvider = Provider<List<DriverRide>>((ref) {
  return const <DriverRide>[];
});

final driverWalletRemoteDataSourceProvider =
    Provider<DriverWalletRemoteDataSource>((ref) {
      return DriverWalletRemoteDataSource();
    });

final driverWalletRepositoryProvider = Provider<DriverWalletRepository>((ref) {
  final remoteDataSource = ref.watch(driverWalletRemoteDataSourceProvider);
  return DriverWalletRepositoryImpl(remoteDataSource: remoteDataSource);
});

final getDriverWalletOverviewUseCaseProvider =
    Provider<GetDriverWalletOverviewUseCase>((ref) {
      final repository = ref.watch(driverWalletRepositoryProvider);
      return GetDriverWalletOverviewUseCase(repository);
    });

final getDriverWalletPackagesUseCaseProvider =
    Provider<GetDriverWalletPackagesUseCase>((ref) {
      final repository = ref.watch(driverWalletRepositoryProvider);
      return GetDriverWalletPackagesUseCase(repository);
    });

final subscribeDriverWalletPackageUseCaseProvider =
    Provider<SubscribeDriverWalletPackageUseCase>((ref) {
      final repository = ref.watch(driverWalletRepositoryProvider);
      return SubscribeDriverWalletPackageUseCase(repository);
    });

final reloadDriverWalletUseCaseProvider = Provider<ReloadDriverWalletUseCase>((
  ref,
) {
  final repository = ref.watch(driverWalletRepositoryProvider);
  return ReloadDriverWalletUseCase(repository);
});

final withdrawDriverWalletUseCaseProvider =
    Provider<WithdrawDriverWalletUseCase>((ref) {
      final repository = ref.watch(driverWalletRepositoryProvider);
      return WithdrawDriverWalletUseCase(repository);
    });
