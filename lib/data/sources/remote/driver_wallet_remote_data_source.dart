library;

import 'package:dio/dio.dart';

import '../../../core/error/exceptions.dart';
import '../api_client.dart';

class DriverWalletRemoteDataSource {
  DriverWalletRemoteDataSource({Dio? dio})
    : _dio = dio ?? ApiClient.instance.dio;

  final Dio _dio;

  Future<dynamic> getReloads() async {
    try {
      final response = await _dio.get('/subscriptions/reloads');
      return response.data;
    } on DioException catch (error) {
      ApiClient.handleDioError(error);
    } catch (error) {
      throw ServerException(
        message: 'Impossible de charger les transactions portefeuille : $error',
      );
    }
  }

  Future<dynamic> getPackages() async {
    try {
      final response = await _dio.get('/packages');
      return response.data;
    } on DioException catch (error) {
      ApiClient.handleDioError(error);
    } catch (error) {
      throw ServerException(
        message: 'Impossible de charger les packages chauffeur : $error',
      );
    }
  }

  Future<dynamic> subscribeToPackage({
    required int sidUserId,
    required int packageId,
  }) async {
    try {
      final response = await _dio.post(
        '/subscriptions/paiement/reload/create',
        data: <String, dynamic>{'sidUserId': sidUserId, 'packageId': packageId},
      );
      final data = response.data;
      if (data is Map && data['success'] == false) {
        throw ServerException(
          message:
              data['message']?.toString() ??
              'Souscription au package impossible.',
          statusCode: response.statusCode,
        );
      }
      return data;
    } on DioException catch (error) {
      ApiClient.handleDioError(error);
    } catch (error) {
      if (error is ServerException) {
        rethrow;
      }
      throw ServerException(
        message: 'Souscription au package impossible : $error',
      );
    }
  }

  Future<dynamic> reloadWallet({
    required double amount,
    String? walletId,
  }) async {
    return _postWalletOperation(
      path: '/subscriptions/reload/drivers/create',
      amount: amount,
      walletId: walletId,
    );
  }

  /// Crée le paiement Orange Money côté serveur et renvoie l'URL de règlement.
  Future<dynamic> initializeOrangeMoneyReload({required double amount}) async {
    try {
      final response = await _dio.post(
        '/orange-money/initialize',
        data: <String, dynamic>{'amount': amount.round()},
      );
      final data = response.data;
      if (data is Map && data['success'] == false) {
        throw ServerException(
          message:
              data['message']?.toString() ??
              "Impossible d'initialiser le paiement Orange Money.",
          statusCode: response.statusCode,
        );
      }
      return data;
    } on DioException catch (error) {
      ApiClient.handleDioError(error);
    } catch (error) {
      if (error is ServerException) {
        rethrow;
      }
      throw ServerException(
        message: "Impossible d'initialiser le paiement Orange Money : $error",
      );
    }
  }

  Future<dynamic> verifyOrangeMoneyReload(String reference) async {
    try {
      final response = await _dio.get(
        '/orange-money/verify/${Uri.encodeComponent(reference)}',
      );
      return response.data;
    } on DioException catch (error) {
      ApiClient.handleDioError(error);
    } catch (error) {
      throw ServerException(
        message: 'Impossible de vérifier le paiement Orange Money : $error',
      );
    }
  }

  Future<void> withdrawWallet({
    required double amount,
    String? walletId,
  }) async {
    await _postWalletOperation(
      path: '/subscriptions/withdraw/drivers/create',
      amount: amount,
      walletId: walletId,
    );
  }

  Future<dynamic> _postWalletOperation({
    required String path,
    required double amount,
    String? walletId,
  }) async {
    try {
      final payload = <String, dynamic>{'amount': amount};
      if (walletId != null && walletId.trim().isNotEmpty) {
        payload['walletId'] = walletId.trim();
      }
      final response = await _dio.post(path, data: payload);
      final data = response.data;
      if (data is Map && data['success'] == false) {
        throw ServerException(
          message:
              data['message']?.toString() ?? 'Operation portefeuille invalide.',
          statusCode: response.statusCode,
        );
      }
      final statusCode = response.statusCode ?? 0;
      if (statusCode < 200 || statusCode >= 300) {
        throw ServerException(message: 'Operation portefeuille invalide.');
      }
      return data;
    } on DioException catch (error) {
      ApiClient.handleDioError(error);
    } catch (error) {
      if (error is ServerException) {
        rethrow;
      }
      throw ServerException(
        message: 'Operation portefeuille impossible : $error',
      );
    }
  }
}
