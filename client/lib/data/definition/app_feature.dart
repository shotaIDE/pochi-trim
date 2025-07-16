import 'package:flutter/foundation.dart';
import 'package:pochi_trim/data/definition/flavor.dart';

final bool showDebugFeatures = !(flavor == Flavor.prod && kReleaseMode);

/// 右上肩にバナーを表示するか否か
///
/// 一般公開アプリ以外は常に表示する
final bool showCustomAppBanner =
    (flavor == Flavor.prod && !kReleaseMode) || flavor != Flavor.prod;

final useFirebaseEmulator = flavor == Flavor.emulator;

const bool isAnalyticsEnabled =
    String.fromEnvironment('ENABLE_ANALYTICS') == 'true' || kReleaseMode;

const bool isCrashlyticsEnabled =
    String.fromEnvironment('ENABLE_CRASHLYTICS') == 'true' || kReleaseMode;

final isRevenueCatEnabled = flavor == Flavor.prod;
