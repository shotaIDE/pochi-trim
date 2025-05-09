import 'package:flutter/foundation.dart';

bool isAnalyticsEnabled() {
  final bool? isEnabledOnEnvironment;

  const isEnabledStringOnEnvironment = String.fromEnvironment(
    'IS_ANALYTICS_ENABLED',
  );
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
