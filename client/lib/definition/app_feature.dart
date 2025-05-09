import 'package:flutter/foundation.dart';

bool isAnalyticsEnabled() {
  const isEnabledStringOnEnvironment = String.fromEnvironment(
    'IS_ANALYTICS_ENABLED',
  );

  final bool? isEnabledOnEnvironment;
  if (isEnabledStringOnEnvironment == 'true') {
    isEnabledOnEnvironment = true;
  } else if (isEnabledStringOnEnvironment == 'false') {
    isEnabledOnEnvironment = false;
  } else {
    isEnabledOnEnvironment = null;
  }

  if (isEnabledOnEnvironment != null) {
    return isEnabledOnEnvironment;
  }

  return kReleaseMode;
}

bool isCrashlyticsEnabled() {
  const isEnabledStringOnEnvironment = String.fromEnvironment(
    'IS_CRASHLYTICS_ENABLED',
  );

  final bool? isEnabledOnEnvironment;
  if (isEnabledStringOnEnvironment == 'true') {
    isEnabledOnEnvironment = true;
  } else if (isEnabledStringOnEnvironment == 'false') {
    isEnabledOnEnvironment = false;
  } else {
    isEnabledOnEnvironment = null;
  }

  if (isEnabledOnEnvironment != null) {
    return isEnabledOnEnvironment;
  }

  return kReleaseMode;
}
