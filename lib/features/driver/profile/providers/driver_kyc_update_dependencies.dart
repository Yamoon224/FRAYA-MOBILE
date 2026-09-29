library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/usecases/driver/kyc/update_driver_kyc_usecase.dart';
import '../../../driver/kyc/providers/driver_kyc_dependencies.dart';

final updateDriverKycUseCaseProvider = Provider<UpdateDriverKycUseCase>((ref) {
  final repository = ref.watch(driverKycRepositoryProvider);
  return UpdateDriverKycUseCase(repository);
});
