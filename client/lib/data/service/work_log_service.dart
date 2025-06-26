import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pochi_trim/data/model/app_session.dart';
import 'package:pochi_trim/data/model/debounce_work_log_exception.dart';
import 'package:pochi_trim/data/model/no_house_id_error.dart';
import 'package:pochi_trim/data/repository/dao/add_work_log_args.dart';
import 'package:pochi_trim/data/repository/work_log_repository.dart';
import 'package:pochi_trim/data/service/auth_service.dart';
import 'package:pochi_trim/data/service/review_service.dart';
import 'package:pochi_trim/data/service/riverpod_extension.dart';
import 'package:pochi_trim/data/service/system_service.dart';
import 'package:pochi_trim/ui/feature/home/home_presenter.dart';
import 'package:pochi_trim/ui/root_presenter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'work_log_service.g.dart';

@riverpod
class DebounceManager extends _$DebounceManager {
  /// デバウンス閾値
  static const debounceThresholdDuration = Duration(milliseconds: 3000);

  @override
  Map<String, DateTime> build() {
    // プロバイダーを3秒間維持
    ref.cacheFor(debounceThresholdDuration);

    return <String, DateTime>{};
  }

  /// 家事の最終登録時刻を記録し、デバウンス判定を行う
  bool shouldRecordWorkLog(String houseWorkId, DateTime currentTime) {
    final lastRegistrationTime = state[houseWorkId];

    if (lastRegistrationTime != null) {
      final timeDifference = currentTime.difference(lastRegistrationTime);
      if (timeDifference < debounceThresholdDuration) {
        return false; // デバウンス期間内なので記録しない
      }
    }

    return true;
  }

  /// 家事の最終登録時刻を記録する
  void recordRegistration(String houseWorkId, DateTime currentTime) {
    state = {...state, houseWorkId: currentTime};

    // 記録時に再度3秒間維持
    ref.cacheFor(debounceThresholdDuration);
  }
}

@riverpod
WorkLogService workLogService(Ref ref) {
  final appSession = ref.watch(unwrappedCurrentAppSessionProvider);
  final workLogRepository = ref.watch(workLogRepositoryProvider);
  final authService = ref.watch(authServiceProvider);
  final systemService = ref.watch(systemServiceProvider);
  final reviewService = ref.watch(reviewServiceProvider);

  switch (appSession) {
    case AppSessionSignedIn(currentHouseId: final currentHouseId):
      return WorkLogService(
        workLogRepository: workLogRepository,
        authService: authService,
        currentHouseId: currentHouseId,
        systemService: systemService,
        reviewService: reviewService,
        ref: ref,
      );
    case AppSessionNotSignedIn():
      throw NoHouseIdError();
  }
}

/// 家事ログに関する共通操作を提供するサービスクラス
class WorkLogService {
  WorkLogService({
    required this.workLogRepository,
    required this.authService,
    required this.currentHouseId,
    required this.systemService,
    required this.reviewService,
    required this.ref,
  });

  final WorkLogRepository workLogRepository;
  final AuthService authService;
  final String currentHouseId;
  final SystemService systemService;
  final ReviewService reviewService;
  final Ref ref;

  Future<String?> recordWorkLog({
    required String houseWorkId,

    /// 家事ログ登録のリクエストが承認されたときに呼び出されるコールバック
    ///
    /// 家事ログの登録における事前バリデーションチェックが成功した場合に呼び出されます。
    /// コールバックの中身は、Hapticフィードバックの処理を実行することなどを想定しています。
    void Function()? onRequestAccepted,
  }) async {
    // 連打防止：同じ家事の場合は3秒以内の連続登録を無視する
    final now = systemService.getCurrentDateTime();
    final debounceManager = ref.read(debounceManagerProvider.notifier);

    if (!debounceManager.shouldRecordWorkLog(houseWorkId, now)) {
      // デバウンス期間内なので専用の例外をスローする
      throw const DebounceWorkLogException();
    }

    final userProfile = await ref.read(currentUserProfileProvider.future);
    if (userProfile == null) {
      return null;
    }

    onRequestAccepted?.call();

    // デバウンス管理に登録時刻を記録
    debounceManager.recordRegistration(houseWorkId, now);

    final addWorkLogArgs = AddWorkLogArgs(
      houseWorkId: houseWorkId,
      completedAt: now,
      completedBy: userProfile.id,
    );

    final String workLogId;
    try {
      workLogId = await workLogRepository.add(addWorkLogArgs);
    } on Exception {
      return null;
    }

    // 家事ログの総数を更新し、レビューをチェック
    await _updateWorkLogCountAndCheckReview();

    return workLogId;
  }

  /// 家事ログの総数を更新し、レビューをチェックする
  Future<void> _updateWorkLogCountAndCheckReview() async {
    try {
      // レビューをチェック（総数の更新も含む）
      await ref.read(checkReviewForWorkLogThresholdProvider.future);
    } on Exception {
      // レビューのチェックに失敗しても、家事ログの記録は成功させる
      // エラーは無視する
    }
  }
}
