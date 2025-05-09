import 'package:flutter/foundation.dart';

bool isAnalyticsEnabled() {
  final isEnabledOnEnvironment = _getBoolFromEnvironmentString(
    key: 'IS_ANALYTICS_ENABLED',
  );
  if (isEnabledOnEnvironment != null) {
    return isEnabledOnEnvironment;
  }

  return kReleaseMode;
}

bool isCrashlyticsEnabled() {
  final isEnabledOnEnvironment = _getBoolFromEnvironmentString(
    key: 'IS_CRASHLYTICS_ENABLED',
  );
  if (isEnabledOnEnvironment != null) {
    return isEnabledOnEnvironment;
  }

  return kReleaseMode;
}

bool? _getBoolFromEnvironmentString({required String key}) {
  final boolString = String.fromEnvironment(key);

  if (boolString == 'true') {
    return true;
  }
  if (boolString == 'false') {
    return false;
  }

  return null;
}
