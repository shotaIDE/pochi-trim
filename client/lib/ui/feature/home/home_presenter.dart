import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pochi_trim/data/model/app_session.dart';
import 'package:pochi_trim/data/model/debounce_work_log_exception.dart';
import 'package:pochi_trim/data/model/delete_house_work_exception.dart';
import 'package:pochi_trim/data/model/delete_work_log_exception.dart';
import 'package:pochi_trim/data/model/house_work.dart';
import 'package:pochi_trim/data/model/no_house_id_error.dart';
import 'package:pochi_trim/data/model/preference_key.dart';
import 'package:pochi_trim/data/model/work_log.dart';
import 'package:pochi_trim/data/repository/house_work_repository.dart';
import 'package:pochi_trim/data/repository/work_log_repository.dart';
import 'package:pochi_trim/data/service/functions_service.dart';
import 'package:pochi_trim/data/service/preference_service.dart';
import 'package:pochi_trim/data/service/review_service.dart';
import 'package:pochi_trim/data/service/system_service.dart';
import 'package:pochi_trim/data/service/work_log_service.dart';
import 'package:pochi_trim/ui/feature/home/work_log_included_house_work.dart';
import 'package:pochi_trim/ui/root_presenter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_presenter.g.dart';

@riverpod
class IsHouseWorkDeleting extends _$IsHouseWorkDeleting {
  @override
  bool build() => false;

  /// 現在の家の指定された家事を削除する
  ///
  /// 削除に失敗した場合は[DeleteHouseWorkException]をスローします。
  Future<void> deleteHouseWork(HouseWork houseWork) async {
    final appSession = ref.read(unwrappedCurrentAppSessionProvider);

    state = true;

    try {
      final String houseId;
      switch (appSession) {
        case AppSessionSignedIn(currentHouseId: final currentHouseId):
          houseId = currentHouseId;
        case AppSessionNotSignedIn():
          throw NoHouseIdError();
      }

      await ref.read(deleteHouseWorkProvider(houseId, houseWork.id).future);
    } finally {
      state = false;
    }
  }
}

@riverpod
Future<List<HouseWork>> houseWorksSortedByMostFrequentlyUsed(Ref ref) async {
  final houseWorks = await ref.watch(_houseWorksFilePrivateProvider.future);
  final completedWorkLogs = await ref.watch(
    _completedWorkLogsFilePrivateProvider.future,
  );

  final completionCountOfHouseWorks = <HouseWork, int>{};

  for (final houseWork in houseWorks) {
    final completionCount = completedWorkLogs
        .where((workLog) => workLog.houseWorkId == houseWork.id)
        .length;

    completionCountOfHouseWorks[houseWork] = completionCount;
  }

  final sortedHouseWorksByCompletionCount = completionCountOfHouseWorks.entries
      .sortedBy((entry) => entry.value)
      .reversed
      .map((entry) => entry.key)
      .toList();

  return sortedHouseWorksByCompletionCount;
}

@riverpod
Future<String?> onCompleteHouseWorkButtonTappedResult(
  Ref ref,
  HouseWork houseWork,
) async {
  final workLogService = ref.read(workLogServiceProvider);
  final systemService = ref.read(systemServiceProvider);

  try {
    return await workLogService.recordWorkLog(
      houseWorkId: houseWork.id,
      onRequestAccepted: systemService.doHapticFeedbackActionReceived,
    );
  } on DebounceWorkLogException {
    await systemService.doHapticFeedbackActionRejected();
    rethrow;
  }
}

@riverpod
Future<String?> onDuplicateWorkLogButtonTappedResult(
  Ref ref,
  WorkLogIncludedHouseWork workLogIncludedHouseWork,
) async {
  final workLogService = ref.read(workLogServiceProvider);
  final systemService = ref.read(systemServiceProvider);

  try {
    return await workLogService.recordWorkLog(
      houseWorkId: workLogIncludedHouseWork.houseWork.id,
      onRequestAccepted: systemService.doHapticFeedbackActionReceived,
    );
  } on DebounceWorkLogException {
    await systemService.doHapticFeedbackActionRejected();
    rethrow;
  }
}

@riverpod
Future<String?> onQuickRegisterButtonPressedResult(
  Ref ref,
  HouseWork houseWork,
) async {
  final workLogService = ref.read(workLogServiceProvider);
  final systemService = ref.read(systemServiceProvider);

  try {
    return await workLogService.recordWorkLog(
      houseWorkId: houseWork.id,
      onRequestAccepted: systemService.doHapticFeedbackActionReceived,
    );
  } on DebounceWorkLogException {
    await systemService.doHapticFeedbackActionRejected();
    rethrow;
  }
}

@riverpod
Stream<List<HouseWork>> _houseWorksFilePrivate(Ref ref) {
  final houseWorkRepository = ref.watch(houseWorkRepositoryProvider);

  return houseWorkRepository.getAll();
}

@riverpod
Stream<List<WorkLog>> _completedWorkLogsFilePrivate(Ref ref) {
  final workLogRepository = ref.watch(workLogRepositoryProvider);

  return workLogRepository.getCompletedWorkLogs();
}

/// 指定されたIDの家事ログを取り消す（削除する）
///
/// Throws:
///   - [DeleteWorkLogException] - 家事ログの削除に失敗した場合
@riverpod
Future<void> undoWorkLog(Ref ref, String workLogId) async {
  final workLogRepository = ref.read(workLogRepositoryProvider);
  await workLogRepository.delete(workLogId);
}

/// アプリが前面に戻った際のレビューチェック
///
/// 分析画面表示後のレビューリクエストをチェックし、
/// 条件を満たしている場合にレビューダイアログを表示します。
@riverpod
Future<void> checkReviewAfterResuming(Ref ref) async {
  // 条件をチェックして、満たしている場合のみレビューをリクエスト
  final shouldRequestReview = await _shouldRequestReview(ref);
  if (shouldRequestReview) {
    final reviewService = ref.read(reviewServiceProvider);
    await reviewService.requestReview();

    // レビューをリクエストしたことを記録
    final preferenceService = ref.read(preferenceServiceProvider);
    await preferenceService.setBool(
      PreferenceKey.hasRequestedReview,
      value: true,
    );
  }
}

/// レビューをリクエストすべきかどうかの条件をチェック
///
/// 以下の条件をすべて満たす場合にtrueを返す：
/// - 3種類以上の家事が登録されている
/// - 10回以上の家事ログが存在する
/// - まだレビューリクエストしていない
Future<bool> _shouldRequestReview(Ref ref) async {
  final preferenceService = ref.read(preferenceServiceProvider);

  // 既にレビューをリクエストしているかチェック
  final hasRequestedReview =
      await preferenceService.getBool(PreferenceKey.hasRequestedReview) ??
      false;
  if (hasRequestedReview) {
    return false;
  }

  try {
    // 家事の種類数をチェック
    final houseWorks = await ref.read(_houseWorksFilePrivateProvider.future);
    if (houseWorks.length < 3) {
      return false;
    }

    // 家事ログの総数をチェック
    final workLogs = await ref.read(
      _completedWorkLogsFilePrivateProvider.future,
    );
    if (workLogs.length < 10) {
      return false;
    }

    return true;
  } on Exception {
    // エラーが発生した場合はfalseを返す
    return false;
  }
}

/// レビューリクエスト状態をリセット（デバッグ用）
@riverpod
Future<void> resetReviewRequestStatus(Ref ref) async {
  final preferenceService = ref.read(preferenceServiceProvider);
  await preferenceService.setBool(
    PreferenceKey.hasRequestedReview,
    value: false,
  );
}
