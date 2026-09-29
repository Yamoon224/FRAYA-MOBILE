import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/repositories/passenger_profile_repository_impl.dart';
import '../../../../data/sources/remote/passenger_profile_remote_data_source.dart';
import '../../../../domain/repositories/passenger_profile_repository.dart';
import '../../../../domain/usecases/passenger/profile/change_passenger_phone.dart';
import '../../../../domain/usecases/passenger/profile/get_passenger_profile.dart';
import '../../../../domain/usecases/passenger/profile/send_phone_change_otp.dart';
import '../../../../domain/usecases/passenger/profile/update_passenger_profile.dart';
import '../../../../domain/usecases/passenger/profile/update_passenger_profile_photo.dart';
import 'profile_photo_picker.dart';

final profileRemoteDataSourceProvider =
    Provider<PassengerProfileRemoteDataSource>((ref) {
      return PassengerProfileRemoteDataSource();
    });

final profileRepositoryProvider = Provider<PassengerProfileRepository>((ref) {
  final remoteDataSource = ref.watch(profileRemoteDataSourceProvider);
  return PassengerProfileRepositoryImpl(remoteDataSource: remoteDataSource);
});

final getPassengerProfileUseCaseProvider =
    Provider<GetPassengerProfileUseCase>((ref) {
      final repository = ref.watch(profileRepositoryProvider);
      return GetPassengerProfileUseCase(repository);
    });

final updatePassengerProfileUseCaseProvider =
    Provider<UpdatePassengerProfileUseCase>((ref) {
      final repository = ref.watch(profileRepositoryProvider);
      return UpdatePassengerProfileUseCase(repository);
    });

final updatePassengerProfilePhotoUseCaseProvider =
    Provider<UpdatePassengerProfilePhotoUseCase>((ref) {
      final repository = ref.watch(profileRepositoryProvider);
      return UpdatePassengerProfilePhotoUseCase(repository);
    });

final profilePhotoPickerProvider = Provider<ProfilePhotoPicker>((ref) {
  return ProfilePhotoPicker();
});

final sendPhoneChangeOtpUseCaseProvider =
    Provider<SendPhoneChangeOtpUseCase>((ref) {
      final repository = ref.watch(profileRepositoryProvider);
      return SendPhoneChangeOtpUseCase(repository);
    });

final changePassengerPhoneUseCaseProvider =
    Provider<ChangePassengerPhoneUseCase>((ref) {
      final repository = ref.watch(profileRepositoryProvider);
      return ChangePassengerPhoneUseCase(repository);
    });
