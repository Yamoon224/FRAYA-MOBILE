library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_register_draft_repository_impl.dart';
import '../../data/sources/local/auth_register_draft_local_data_source.dart';
import '../../domain/repositories/auth_register_draft_repository.dart';

final authRegisterDraftLocalDataSourceProvider =
    Provider<AuthRegisterDraftLocalDataSource>((ref) {
      return AuthRegisterDraftLocalDataSource();
    });

final authRegisterDraftRepositoryProvider =
    Provider<AuthRegisterDraftRepository>((ref) {
      final localDataSource = ref.watch(
        authRegisterDraftLocalDataSourceProvider,
      );
      return AuthRegisterDraftRepositoryImpl(localDataSource: localDataSource);
    });
