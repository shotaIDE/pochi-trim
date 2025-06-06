import 'package:flutter/foundation.dart';
import 'package:pochi_trim/data/definition/flavor.dart';

final bool showDebugFeatures = !(flavor == Flavor.prod && kReleaseMode);

final bool showCustomAppBanner =
    (flavor == Flavor.prod && !kReleaseMode) || flavor != Flavor.prod;

final bool showAppDebugBanner = !showCustomAppBanner && showDebugFeatures;

final useFirebaseEmulator = flavor == Flavor.emulator;

const bool isAnalyticsEnabled =
    String.fromEnvironment('ENABLE_ANALYTICS') == 'true' || kReleaseMode;

const bool isCrashlyticsEnabled =
    String.fromEnvironment('ENABLE_CRASHLYTICS') == 'true' || kReleaseMode;

final isRevenueCatEnabled = flavor == Flavor.prod;
