import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pochi_trim/data/model/debounce_work_log_exception.dart';
import 'package:pochi_trim/data/model/delete_house_work_exception.dart';
import 'package:pochi_trim/data/model/delete_work_log_exception.dart';
import 'package:pochi_trim/data/model/house_work.dart';
import 'package:pochi_trim/data/model/preference_key.dart';
import 'package:pochi_trim/data/model/work_log.dart';
import 'package:pochi_trim/data/repository/house_repository.dart';
import 'package:pochi_trim/data/repository/house_work_repository.dart';
import 'package:pochi_trim/data/repository/work_log_repository.dart';
import 'package:pochi_trim/data/service/functions_service.dart';
import 'package:pochi_trim/data/service/in_app_review_service.dart';
import 'package:pochi_trim/data/service/preference_service.dart';
import 'package:pochi_trim/data/service/system_service.dart';
import 'package:pochi_trim/data/service/work_log_service.dart';
import 'package:pochi_trim/ui/feature/home/work_log_included_house_work.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_presenter.g.dart';

@riverpod
Future<bool> shouldShowHowToRegisterWorkLogsTutorial(Ref ref) async {
  final preferenceService = ref.read(preferenceServiceProvider);

  final shouldShow = await preferenceService.getBool(
    PreferenceKey.shouldShowHowToRegisterWorkLogsTutorial,
  );
  return shouldShow ?? false;
}

@riverpod
Future<void> onFinishHowToRegisterWorkLogsTutorial(Ref ref) async {
  final preferenceService = ref.read(preferenceServiceProvider);

  await preferenceService.setBool(
    PreferenceKey.shouldShowHowToRegisterWorkLogsTutorial,
    value: false,
  );
}

@riverpod
Future<void> onSkipHowToRegisterWorkLogsTutorial(Ref ref) async {
  final preferenceService = ref.read(preferenceServiceProvider);

  await preferenceService.setBool(
    PreferenceKey.shouldShowHowToRegisterWorkLogsTutorial,
    value: false,
  );
}

@riverpod
Future<bool> shouldShowHowToCheckWorkLogsAndAnalysisTutorial(Ref ref) async {
  final preferenceService = ref.read(preferenceServiceProvider);

  final shouldShow = await preferenceService.getBool(
    PreferenceKey.shouldShowHowToCheckWorkLogsAndAnalysisTutorial,
  );
  return shouldShow ?? false;
}

@riverpod
Future<void> onFinishHowToCheckWorkLogsAndAnalysisTutorial(Ref ref) async {
  final preferenceService = ref.read(preferenceServiceProvider);

  await preferenceService.setBool(
    PreferenceKey.shouldShowHowToCheckWorkLogsAndAnalysisTutorial,
    value: false,
  );
}

@riverpod
Future<void> onSkipHowToCheckWorkLogsAndAnalysisTutorial(Ref ref) async {
  final preferenceService = ref.read(preferenceServiceProvider);

  await preferenceService.setBool(
    PreferenceKey.shouldShowHowToCheckWorkLogsAndAnalysisTutorial,
    value: false,
  );
}

@riverpod
class IsHouseWorkDeleting extends _$IsHouseWorkDeleting {
  @override
  bool build() => false;

  /// 現在の家の指定された家事を削除する
  ///
  /// 削除に失敗した場合は[DeleteHouseWorkException]をスローします。
  Future<void> deleteHouseWork(HouseWork houseWork) async {
    final currentHouseId = ref.read(unwrappedCurrentHouseIdProvider);

    state = true;

    try {
      await ref.read(
        deleteHouseWorkProvider(currentHouseId, houseWork.id).future,
      );
    } finally {
      state = false;
    }
  }
}

/// 更新頻度が絞られている、頻繁に使用される家事のリスト
///
/// 以下の条件を満たす場合に更新されます。
/// - 家事が追加された
/// - 家事が削除された
@riverpod
class ThrottledHouseWorksSortedByMostFrequentlyUsed
    extends _$ThrottledHouseWorksSortedByMostFrequentlyUsed {
  List<HouseWork>? _previous;

  @override
  Stream<List<HouseWork>> build() async* {
    final next = await ref.watch(
      _houseWorksSortedByMostFrequentlyUsedProvider.future,
    );

    final previous = _previous;
    if (previous != null && previous.length == next.length) {
      _previous = next;
      return;
    }

    _previous = next;

    yield next;
  }
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

/// 指定されたIDの家事ログを取り消す（削除する）
///
/// Throws:
///   - [DeleteWorkLogException] - 家事ログの削除に失敗した場合
@riverpod
Future<void> undoWorkLog(Ref ref, String workLogId) async {
  final workLogRepository = ref.read(workLogRepositoryProvider);
  await workLogRepository.delete(workLogId);
}

/// 初回分析後のアプリレビューリクエスト
///
/// 初めて分析画面が表示されて条件を満たしている場合にアプリレビューダイアログを表示します。
/// アプリレビューはOS制限により多くの回数リクエストできないため、
/// 条件で縛りつつ必要なタイミングでのみリクエストします。
@riverpod
Future<void> requestAppReviewAfterFirstAnalysisIfNeeded(Ref ref) async {
  final preferenceService = ref.read(preferenceServiceProvider);

  // 既に分析画面でのレビューをリクエスト済みかチェック
  final hasRequestedForAnalysis =
      await preferenceService.getBool(
        PreferenceKey.hasRequestedReviewForAnalysisView,
      ) ??
      false;
  if (hasRequestedForAnalysis) {
    return;
  }

  // レビューリクエスト条件をチェック
  // 条件：3種類以上の家事が登録されている
  final houseWorks = await ref.read(_houseWorksFilePrivateProvider.future);
  if (houseWorks.length < 3) {
    return;
  }

  // 条件：10回以上の家事ログが存在する
  final totalWorkLogCount =
      await preferenceService.getInt(
        PreferenceKey.workLogCountForAppReviewRequest,
      ) ??
      0;
  if (totalWorkLogCount < 10) {
    return;
  }

  // 条件を満たしているのでアプリレビューをリクエスト
  final inAppReviewService = ref.read(inAppReviewServiceProvider);
  await inAppReviewService.requestReview();

  // 分析画面でのレビューリクエスト完了を記録
  await preferenceService.setBool(
    PreferenceKey.hasRequestedReviewForAnalysisView,
    value: true,
  );
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

@riverpod
Future<List<HouseWork>> _houseWorksSortedByMostFrequentlyUsed(Ref ref) async {
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
