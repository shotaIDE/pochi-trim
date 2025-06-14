import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pochi_trim/data/model/app_session.dart';
import 'package:pochi_trim/data/model/no_house_id_error.dart';
import 'package:pochi_trim/data/model/work_log.dart';
import 'package:pochi_trim/data/repository/work_log_repository.dart';
import 'package:pochi_trim/data/service/auth_service.dart';
import 'package:pochi_trim/data/service/riverpod_extension.dart';
import 'package:pochi_trim/data/service/system_service.dart';
import 'package:pochi_trim/ui/root_presenter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'work_log_service.g.dart';

@riverpod
class DebounceManager extends _$DebounceManager {
  /// デバウンス閾値（ミリ秒）
  static const _debounceThresholdMilliseconds = 3000;

  @override
  Map<String, DateTime> build() {
    // プロバイダーを3秒間維持
    ref.cacheFor(const Duration(milliseconds: _debounceThresholdMilliseconds));

    return <String, DateTime>{};
  }

  /// 家事の最終登録時刻を記録し、デバウンス判定を行う
  bool shouldRecordWorkLog(String houseWorkId, DateTime currentTime) {
    final lastRegistrationTime = state[houseWorkId];

    if (lastRegistrationTime != null) {
      final timeDifference = currentTime.difference(lastRegistrationTime);
      if (timeDifference.inMilliseconds < _debounceThresholdMilliseconds) {
        return false; // デバウンス期間内なので記録しない
      }
    }

    return true;
  }

  /// 家事の最終登録時刻を記録する
  void recordRegistration(String houseWorkId, DateTime currentTime) {
    state = {...state, houseWorkId: currentTime};

    // 記録時に再度3秒間維持
    ref.cacheFor(const Duration(milliseconds: _debounceThresholdMilliseconds));
  }
}

@riverpod
WorkLogService workLogService(Ref ref) {
  final appSession = ref.watch(unwrappedCurrentAppSessionProvider);
  final workLogRepository = ref.watch(workLogRepositoryProvider);
  final authService = ref.watch(authServiceProvider);
  final systemService = ref.watch(systemServiceProvider);

  switch (appSession) {
    case AppSessionSignedIn(currentHouseId: final currentHouseId):
      return WorkLogService(
        workLogRepository: workLogRepository,
        authService: authService,
        currentHouseId: currentHouseId,
        systemService: systemService,
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
    required this.ref,
  });

  final WorkLogRepository workLogRepository;
  final AuthService authService;
  final String currentHouseId;
  final SystemService systemService;
  final Ref ref;

  Future<bool> recordWorkLog({
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
      // デバウンス期間内なので記録しない
      return false;
    }

    final userProfile = await ref.read(currentUserProfileProvider.future);
    if (userProfile == null) {
      return false;
    }

    onRequestAccepted?.call();

    // デバウンス管理に登録時刻を記録
    debounceManager.recordRegistration(houseWorkId, now);

    final workLog = WorkLog(
      id: '', // 新規登録のため空文字列
      houseWorkId: houseWorkId,
      completedAt: now,
      completedBy: userProfile.id,
    );

    try {
      await workLogRepository.save(workLog);
    } on Exception {
      return false;
    }

    return true;
  }

  /// 過去1ヶ月間の家事ログをページネーションで取得
  Future<List<WorkLog>> getCompletedWorkLogsWithPagination({
    DateTime? lastCompletedAt,
    int limit = 20,
  }) {
    return workLogRepository.getCompletedWorkLogsOnceWithPagination(
      lastCompletedAt: lastCompletedAt,
      limit: limit,
    );
  }

  /// 過去1ヶ月間の家事ログをリアルタイムで取得（ストリーム）
  Stream<List<WorkLog>> getCompletedWorkLogsStreamWithPagination({
    DateTime? lastCompletedAt,
    int limit = 20,
  }) {
    return workLogRepository.getCompletedWorkLogsWithPagination(
      lastCompletedAt: lastCompletedAt,
      limit: limit,
    );
  }
}
