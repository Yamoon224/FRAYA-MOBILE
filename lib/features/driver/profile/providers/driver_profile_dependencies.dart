import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/repositories/driver_profile_repository_impl.dart';
import '../../../../data/sources/remote/driver_profile_remote_data_source.dart';
import '../../../../domain/repositories/driver_profile_repository.dart';
import '../../../../domain/usecases/driver/profile/change_driver_phone.dart';
import '../../../../domain/usecases/driver/profile/send_driver_phone_change_otp.dart';
import '../../../../domain/usecases/driver/profile/update_driver_profile.dart';
import '../../../../domain/usecases/driver/profile/update_driver_profile_photo.dart';
import '../../../passenger/profile/providers/profile_photo_picker.dart';

final driverProfileRemoteDataSourceProvider =
    Provider<DriverProfileRemoteDataSource>((ref) {
      return DriverProfileRemoteDataSource();
    });

final driverProfileRepositoryProvider =
    Provider<DriverProfileRepository>((ref) {
      final ds = ref.watch(driverProfileRemoteDataSourceProvider);
      return DriverProfileRepositoryImpl(remoteDataSource: ds);
    });

final updateDriverProfileUseCaseProvider =
    Provider<UpdateDriverProfileUseCase>((ref) {
      return UpdateDriverProfileUseCase(
        ref.watch(driverProfileRepositoryProvider),
      );
    });

final updateDriverProfilePhotoUseCaseProvider =
    Provider<UpdateDriverProfilePhotoUseCase>((ref) {
      return UpdateDriverProfilePhotoUseCase(
        ref.watch(driverProfileRepositoryProvider),
      );
    });

final sendDriverPhoneChangeOtpUseCaseProvider =
    Provider<SendDriverPhoneChangeOtpUseCase>((ref) {
      return SendDriverPhoneChangeOtpUseCase(
        ref.watch(driverProfileRepositoryProvider),
      );
    });

final changeDriverPhoneUseCaseProvider =
    Provider<ChangeDriverPhoneUseCase>((ref) {
      return ChangeDriverPhoneUseCase(
        ref.watch(driverProfileRepositoryProvider),
      );
    });

final driverProfilePhotoPickerProvider = Provider<ProfilePhotoPicker>((ref) {
  return ProfilePhotoPicker();
});
