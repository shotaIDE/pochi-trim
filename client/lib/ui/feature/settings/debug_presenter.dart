import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pochi_trim/data/model/preference_key.dart';
import 'package:pochi_trim/data/service/preference_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'debug_presenter.g.dart';

/// 最初の家事チュートリアル状態をリセット（デバッグ用）
@riverpod
Future<void> resetFirstHouseWorkTutorialStatus(Ref ref) async {
  final preferenceService = ref.read(preferenceServiceProvider);
  await preferenceService.setBool(
    PreferenceKey.hasShownFirstHouseWorkTutorial,
    value: false,
  );
}

/// 30回レビューリクエスト状態をリセット（デバッグ用）
@riverpod
Future<void> reset30WorkLogsReviewRequestStatus(Ref ref) async {
  final preferenceService = ref.read(preferenceServiceProvider);
  await preferenceService.setBool(
    PreferenceKey.hasRequestedAppReviewWhenOver30WorkLogs,
    value: false,
  );
}

/// 100回レビューリクエスト状態をリセット（デバッグ用）
@riverpod
Future<void> reset100WorkLogsReviewRequestStatus(Ref ref) async {
  final preferenceService = ref.read(preferenceServiceProvider);
  await preferenceService.setBool(
    PreferenceKey.hasRequestedReviewWhenOver100WorkLogs,
    value: false,
  );
}

/// 分析画面レビューリクエスト状態をリセット（デバッグ用）
@riverpod
Future<void> resetAnalysisReviewRequestStatus(Ref ref) async {
  final preferenceService = ref.read(preferenceServiceProvider);
  await preferenceService.setBool(
    PreferenceKey.hasRequestedReviewForAnalysisView,
    value: false,
  );
}

/// 家事ログ完了回数を0にリセット（デバッグ用）
@riverpod
Future<void> resetWorkLogCountForAppReviewRequest(Ref ref) async {
  final preferenceService = ref.read(preferenceServiceProvider);
  await preferenceService.setInt(
    PreferenceKey.workLogCountForAppReviewRequest,
    value: 0,
  );
}

/// 最初の家事ログチュートリアル状態をリセット（デバッグ用）
@riverpod
Future<void> resetFirstWorkLogTutorialStatus(Ref ref) async {
  final preferenceService = ref.read(preferenceServiceProvider);
  await preferenceService.setBool(
    PreferenceKey.hasShownFirstWorkLogTutorial,
    value: false,
  );
}
