import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'error_report_service.g.dart';

@riverpod
ErrorReportService errorReportService(Ref _) {
  return ErrorReportService();
}

class ErrorReportService {
  final _logger = Logger('ErrorReportService');

  /// CrashlyticsにユーザーIDを設定する
  Future<void> setUserId(String userId) async {
    try {
      await FirebaseCrashlytics.instance.setUserIdentifier(userId);
      _logger.info('Set user ID in Crashlytics: $userId');
    } on Exception catch (e, stack) {
      _logger.warning('Failed to set user ID in Crashlytics', e);

      await FirebaseCrashlytics.instance.recordError(e, stack);
    }
  }

  /// CrashlyticsのユーザーIDをクリアする
  Future<void> clearUserId() async {
    try {
      await FirebaseCrashlytics.instance.setUserIdentifier('');
      _logger.info('Cleared user ID in Crashlytics');
    } on Exception catch (e, stack) {
      _logger.warning('Failed to clear user ID in Crashlytics', e);

      await FirebaseCrashlytics.instance.recordError(e, stack);
    }
  }

  /// エラーをCrashlyticsに記録する
  Future<void> recordError(
    dynamic exception,
    StackTrace stackTrace, {
    bool fatal = false,
  }) async {
    try {
      await FirebaseCrashlytics.instance.recordError(
        exception,
        stackTrace,
        fatal: fatal,
      );
      _logger.info('Recorded error in Crashlytics: $exception');
    } on Exception catch (e) {
      _logger.warning('Failed to record error in Crashlytics', e);
    }
  }
}
