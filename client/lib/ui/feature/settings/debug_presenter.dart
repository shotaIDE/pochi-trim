import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pochi_trim/data/model/preference_key.dart';
import 'package:pochi_trim/data/repository/house_repository.dart';
import 'package:pochi_trim/data/service/auth_service.dart';
import 'package:pochi_trim/data/service/preference_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'debug_presenter.g.dart';

@riverpod
Future<void> logout(Ref ref) async {
  // TODO(ide): settings_presenter のものと共通化したい
  await ref.read(authServiceProvider).signOut();

  await ref.read(currentHouseIdProvider.notifier).removeId();
}

@riverpod
Future<void> resetHowToRegisterWorkLogsTutorialStatus(Ref ref) async {
  final preferenceService = ref.read(preferenceServiceProvider);
  await preferenceService.setBool(
    PreferenceKey.shouldShowHowToRegisterWorkLogsTutorial,
    value: true,
  );
}

@riverpod
Future<void> resetHowToCheckWorkLogsAndAnalysisTutorialStatus(Ref ref) async {
  final preferenceService = ref.read(preferenceServiceProvider);
  await preferenceService.setBool(
    PreferenceKey.shouldShowHowToCheckWorkLogsAndAnalysisTutorial,
    value: true,
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
