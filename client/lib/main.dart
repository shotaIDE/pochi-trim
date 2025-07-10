import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logging/logging.dart';
import 'package:pochi_trim/data/definition/app_definition.dart';
import 'package:pochi_trim/data/definition/app_feature.dart';
import 'package:pochi_trim/data/definition/flavor.dart';
import 'package:pochi_trim/data/service/in_app_purchase_service.dart';
import 'package:pochi_trim/data/service/in_app_purchase_service_mock.dart';
import 'package:pochi_trim/ui/root_app.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'firebase_options_dev.dart' as dev;
import 'firebase_options_emulator.dart' as emulator;
import 'firebase_options_prod.dart' as prod;

// アプリケーションのロガー
final _logger = Logger('PochiTrim');

// ロギングシステムの初期化
void _setupLogging() {
  // ルートロガーの設定
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // 開発環境では詳細なログを出力
    final message =
        '${record.level.name}: ${record.time}: '
        '${record.loggerName}: ${record.message}';

    // エラーと警告はスタックトレースも出力
    if (record.level >= Level.WARNING && record.error != null) {
      debugPrint('$message\nError: ${record.error}\n${record.stackTrace}');
    } else {
      debugPrint(message);
    }
  });

  _logger.info('ロギングシステムを初期化しました');
}

// Firebase Emulatorのホスト情報を取得する関数
String _getEmulatorHost() {
  try {
    // dart-define-from-fileから設定を読み込む
    const emulatorHost = String.fromEnvironment(
      'EMULATOR_HOST',
      defaultValue: '127.0.0.1',
    );
    return emulatorHost;
  } on Exception catch (e) {
    _logger.warning('エミュレーター設定の読み込みに失敗しました', e);
    // デフォルト値を返す
    return '127.0.0.1';
  }
}

// Firebase Emulatorの設定を行う関数
Future<void> _setupFirebaseEmulators(String host) async {
  await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
  FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ロギングシステムの初期化
  _setupLogging();

  try {
    await Firebase.initializeApp(options: _getFirebaseOptions());

    _logger.info('Firebase initialized successfully');

    if (useFirebaseEmulator) {
      final emulatorHost = _getEmulatorHost();
      _logger.info('エミュレーターホスト: $emulatorHost');

      await _setupFirebaseEmulators(emulatorHost);
      _logger.info('Firebase Emulator設定を適用しました');
    }

    // アプリのライフサイクル全体で一度だけの初期化する
    await GoogleSignIn.instance.initialize();
    _logger.info('Googleでサインインのライブラリを初期化しました');
  } on Exception catch (e) {
    _logger.severe('認証モジュールの初期化に失敗しました', e);
    // 初期化できなくても、アプリを続行する
  }

  await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(
    isAnalyticsEnabled,
  );

  if (isCrashlyticsEnabled) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  if (isRevenueCatEnabled) {
    await _setupRevenueCat();
  }

  runApp(ProviderScope(overrides: _getOverrides(), child: const RootApp()));
}

FirebaseOptions? _getFirebaseOptions() {
  switch (flavor) {
    case Flavor.emulator:
      return emulator.DefaultFirebaseOptions.currentPlatform;
    case Flavor.dev:
      return dev.DefaultFirebaseOptions.currentPlatform;
    case Flavor.prod:
      return prod.DefaultFirebaseOptions.currentPlatform;
  }
}

Future<void> _setupRevenueCat() async {
  final PurchasesConfiguration configuration;
  if (Platform.isAndroid) {
    configuration = PurchasesConfiguration(revenueCatProjectGoogleApiKey);
  } else if (Platform.isIOS) {
    configuration = PurchasesConfiguration(revenueCatProjectAppleApiKey);
  } else {
    throw Exception('Unsupported platform: ${Platform.operatingSystem}');
  }

  await Purchases.configure(configuration);
}

List<Override> _getOverrides() {
  final overrides = <Override>[];

  if (!isRevenueCatEnabled) {
    overrides.add(isProUserProvider.overrideWith(IsProUserMock.new));
  }

  return overrides;
}
