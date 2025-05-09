import 'package:flutter/foundation.dart';

bool isAnalyticsEnabled() {
  const environmentKey = 'IS_ANALYTICS_ENABLED';
  final bool? enableAnalytics;

  if (const bool.hasEnvironment(environmentKey)) {
    enableAnalytics = const bool.fromEnvironment(environmentKey);
  } else {
    enableAnalytics = null;
  }

  if (enableAnalytics != null) {
    return true;
  }

  return kReleaseMode;
}
