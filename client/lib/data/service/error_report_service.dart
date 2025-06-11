import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      _logger.info('CrashlyticsにユーザーID設定完了: $userId');
    } on Exception catch (e, stack) {
      _logger.warning('CrashlyticsのユーザーID設定に失敗しました', e);

      await FirebaseCrashlytics.instance.recordError(e, stack);
    }
  }

  /// CrashlyticsのユーザーIDをクリアする
  Future<void> clearUserId() async {
    try {
      await FirebaseCrashlytics.instance.setUserIdentifier('');
      _logger.info('CrashlyticsのユーザーIDをクリアしました');
    } on Exception catch (e, stack) {
      _logger.warning('CrashlyticsのユーザーIDクリアに失敗しました', e);

      await FirebaseCrashlytics.instance.recordError(e, stack);
    }
  }
}
