import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/services/passenger_promotions_service.dart';
import '../../../../shared/models/auth_state.dart';
import '../../auth/providers/passenger_auth_provider.dart';
import '../models/promo_apply_result.dart';

class PassengerPromotionsState {
  const PassengerPromotionsState({
    this.isLoading = false,
    this.result,
    this.errorMessage,
  });

  final bool isLoading;
  final PromoApplyResult? result;
  final String? errorMessage;

  PassengerPromotionsState copyWith({
    bool? isLoading,
    PromoApplyResult? result,
    String? errorMessage,
    bool clearResult = false,
  }) {
    return PassengerPromotionsState(
      isLoading: isLoading ?? this.isLoading,
      result: clearResult ? null : (result ?? this.result),
      errorMessage: errorMessage,
    );
  }
}

class PassengerPromotionsNotifier
    extends StateNotifier<PassengerPromotionsState> {
  PassengerPromotionsNotifier({
    required PassengerPromotionsService service,
    required Ref ref,
  }) : _service = service,
       _ref = ref,
       super(const PassengerPromotionsState());

  final PassengerPromotionsService _service;
  final Ref _ref;

  Future<void> applyCode({
    required String code,
    required double initialPrice,
    int? courseId,
  }) async {
    final userId = _extractUserId(_ref.read(passengerAuthProvider));
    if (userId == null) {
      state = state.copyWith(
        errorMessage: 'Utilisateur non authentifie.',
        clearResult: true,
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      clearResult: true,
    );
    try {
      final result = await _service.applyCode(
        code: code,
        userId: userId,
        initialPrice: initialPrice,
        courseId: courseId,
      );
      state = state.copyWith(isLoading: false, result: result);
    } on ServerException catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.message);
    } on NetworkException catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.message);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Erreur promotion: $error',
      );
    }
  }

  int? _extractUserId(AuthState authState) {
    final userData = authState.userData;
    if (userData == null) return null;
    final raw =
        userData['id'] ??
        userData['userId'] ??
        userData['SID'] ??
        userData['sub'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '');
  }
}

final passengerPromotionsServiceProvider = Provider<PassengerPromotionsService>(
  (ref) => PassengerPromotionsService(),
);

final passengerPromotionsProvider =
    StateNotifierProvider<
      PassengerPromotionsNotifier,
      PassengerPromotionsState
    >((ref) {
      final service = ref.watch(passengerPromotionsServiceProvider);
      return PassengerPromotionsNotifier(service: service, ref: ref);
    });
