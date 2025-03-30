import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/common/theme/app_theme.dart';
import 'package:house_worker/features/auth/login_screen.dart';
import 'package:house_worker/features/home/home_screen.dart';
import 'package:house_worker/flavor_config.dart';
import 'package:house_worker/services/auth_service.dart';
import 'package:logging/logging.dart';

import 'firebase_options_dev.dart' as dev;
import 'firebase_options_prod.dart' as prod;

// アプリケーションのロガー
final _logger = Logger('HouseWorker');

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
String getEmulatorHost() {
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
void setupFirebaseEmulators(String host) {
  FirebaseAuth.instance.useAuthEmulator(host, 9099);
  FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
  // Functionsも使用する場合は以下を追加
  // FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
}

// 環境設定を行う関数
void setupFlavorConfig() {
  // Flutterのビルド設定から自動的にflavorを取得
  // Flutterのビルドシステムで設定されたFLAVOR環境変数を使用
  const flavorName = String.fromEnvironment(
    'FLUTTER_APP_FLAVOR',
    defaultValue: 'emulator',
  );

  _logger.info('検出されたflavor: $flavorName');

  switch (flavorName.toLowerCase()) {
    case 'prod':
      FlavorConfig(
        flavor: Flavor.prod,
        name: 'PROD',
        color: Colors.blue,
        firebaseOptions: prod.DefaultFirebaseOptions.currentPlatform,
      );
    case 'emulator':
      FlavorConfig(
        flavor: Flavor.emulator,
        name: 'EMULATOR',
        color: Colors.purple,
        useFirebaseEmulator: true,
      );
    case 'dev':
    default:
      FlavorConfig(
        flavor: Flavor.dev,
        name: 'DEV',
        color: Colors.green,
        firebaseOptions: dev.DefaultFirebaseOptions.currentPlatform,
      );
  }

  _logger.info('アプリケーション環境: ${FlavorConfig.instance.name}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ロギングシステムの初期化
  _setupLogging();

  // 環境設定の初期化
  setupFlavorConfig();

  try {
    // Firebase初期化
    if (FlavorConfig.instance.firebaseOptions != null) {
      await Firebase.initializeApp(
        options: FlavorConfig.instance.firebaseOptions,
      );
    } else {
      await Firebase.initializeApp();
    }
    _logger.info('Firebase initialized successfully');

    // エミュレーターの設定が有効な場合のみ適用
    if (FlavorConfig.instance.useFirebaseEmulator) {
      // エミュレーターのホスト情報を取得
      final emulatorHost = getEmulatorHost();
      _logger.info('エミュレーターホスト: $emulatorHost');

      // エミュレーターの設定を適用
      setupFirebaseEmulators(emulatorHost);
      _logger.info('Firebase Emulator設定を適用しました');
    }

    // 既存ユーザーのログイン状態を確認してUIDをログ出力
    final container = ProviderContainer();
    container.read(authServiceProvider).checkCurrentUser();
  } on Exception catch (e) {
    _logger.severe('Failed to initialize Firebase', e);
    // Firebase が初期化できなくても、アプリを続行する
  }

  runApp(const ProviderScope(child: HouseWorkerApp()));
}

class HouseWorkerApp extends StatelessWidget {
  const HouseWorkerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'House Worker ${FlavorConfig.instance.name}',
      theme: getLightTheme(),
      darkTheme: getDarkTheme(),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: !FlavorConfig.isProd,
      builder: (context, child) {
        // Flavorに応じたバナーを表示（本番環境以外）
        if (!FlavorConfig.isProd) {
          return Banner(
            message: FlavorConfig.instance.name,
            location: BannerLocation.topEnd,
            color: FlavorConfig.instance.color,
            child: child,
          );
        }
        return child!;
      },
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          return const HomeScreen();
        } else {
          return const LoginScreen();
        }
      },
      loading:
          () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
      error:
          (error, stackTrace) => Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('エラーが発生しました'),
                  const SizedBox(height: 10),
                  Text(error.toString()),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      ref.invalidate(authStateProvider);
                    },
                    child: const Text('再試行'),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
