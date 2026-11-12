library;

import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../config/app_flavor.dart';
import '../config/store_links.dart';
import '../utils/logger.dart';

/// Une version plus récente que celle installée est disponible sur le store.
class AvailableUpdate {
  const AvailableUpdate({
    required this.storeVersion,
    this.storeUrl,
    this.canUpdateInApp = false,
  });

  /// Numéro de version affiché à l'utilisateur ; null quand le store ne le donne pas (Play Store).
  final String? storeVersion;

  /// Fiche de l'application sur le store, ouverte si la mise à jour intégrée n'est pas possible.
  final String? storeUrl;

  /// Android : Google Play peut télécharger et installer la mise à jour sans quitter l'application.
  final bool canUpdateInApp;

  /// Clé de la version proposée, pour ne pas redemander la même version trop souvent.
  String get key => storeVersion ?? 'play';
}

/// Compare deux numéros de version « 1.0.5 » ; positif si [a] est plus récent que [b].
int compareVersions(String a, String b) {
  List<int> parts(String v) => v
      .split('+')
      .first
      .split('.')
      .map((p) => int.tryParse(p.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
      .toList();
  final pa = parts(a);
  final pb = parts(b);
  final length = pa.length > pb.length ? pa.length : pb.length;
  for (var i = 0; i < length; i++) {
    final x = i < pa.length ? pa[i] : 0;
    final y = i < pb.length ? pb[i] : 0;
    if (x != y) return x - y;
  }
  return 0;
}

/// Détecte une nouvelle version publiée sur le store et l'installe à la demande de l'utilisateur.
///
/// Android : l'API de mise à jour de Google Play ne signale que les versions réellement publiées
/// pour cet appareil. iOS : la fiche publique App Store est interrogée par identifiant de bundle.
/// Toute erreur (hors ligne, version de développement, installation hors store) est silencieuse :
/// l'application ne doit jamais être gênée par cette vérification.
class AppUpdateService {
  AppUpdateService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  static const _dismissedKeyPref = 'app_update_dismissed_key';
  static const _dismissedAtPref = 'app_update_dismissed_at';
  static const snoozeDuration = Duration(hours: 24);

  Future<AvailableUpdate?> check() async {
    final flavor = AppConfig.instance.flavor;
    if (flavor == AppFlavor.dev) return null;
    try {
      if (Platform.isAndroid) return await _checkAndroid();
      if (Platform.isIOS) return await _checkIos();
    } catch (error, stackTrace) {
      logger.info(
        'Vérification de mise à jour ignorée: $error',
        null,
        stackTrace,
      );
    }
    return null;
  }

  Future<AvailableUpdate?> _checkAndroid() async {
    final info = await InAppUpdate.checkForUpdate();
    if (info.updateAvailability != UpdateAvailability.updateAvailable) {
      return null;
    }
    final link = StoreLinks.shareLink(
      isAndroid: true,
      flavor: AppConfig.instance.flavor,
    );
    return AvailableUpdate(
      storeVersion: null,
      storeUrl: link,
      canUpdateInApp: info.immediateUpdateAllowed,
    );
  }

  Future<AvailableUpdate?> _checkIos() async {
    final package = await PackageInfo.fromPlatform();
    final bundleId = package.packageName;
    final current = package.version;
    final response = await _dio.get<dynamic>(
      'https://itunes.apple.com/lookup',
      queryParameters: {'bundleId': bundleId, 'country': 'ci'},
      options: Options(
        receiveTimeout: const Duration(seconds: 6),
        sendTimeout: const Duration(seconds: 6),
      ),
    );
    final data = response.data is String
        ? null
        : response.data as Map<String, dynamic>?;
    final results = data?['results'];
    if (results is! List || results.isEmpty) return null;
    final app = results.first as Map<String, dynamic>;
    final version = app['version']?.toString();
    if (version == null || compareVersions(version, current) <= 0) return null;
    return AvailableUpdate(
      storeVersion: version,
      storeUrl: app['trackViewUrl']?.toString(),
    );
  }

  /// Lance la mise à jour : intégrée sous Android quand c'est possible, sinon ouverture de la fiche du store.
  Future<void> startUpdate(AvailableUpdate update) async {
    if (update.canUpdateInApp) {
      try {
        await InAppUpdate.performImmediateUpdate();
        return;
      } catch (error, stackTrace) {
        logger.info(
          'Mise à jour intégrée impossible: $error',
          null,
          stackTrace,
        );
      }
    }
    final url = update.storeUrl;
    if (url == null) return;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  /// Faux quand l'utilisateur a repoussé cette version il y a moins de 24 h.
  Future<bool> shouldPrompt(AvailableUpdate update, {DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString(_dismissedKeyPref);
    final at = prefs.getInt(_dismissedAtPref);
    if (key != update.key || at == null) return true;
    final since = (now ?? DateTime.now()).difference(
      DateTime.fromMillisecondsSinceEpoch(at),
    );
    return since >= snoozeDuration;
  }

  Future<void> snooze(AvailableUpdate update, {DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dismissedKeyPref, update.key);
    await prefs.setInt(
      _dismissedAtPref,
      (now ?? DateTime.now()).millisecondsSinceEpoch,
    );
  }
}
