import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pochi_trim/data/model/app_session.dart';
import 'package:pochi_trim/data/model/no_house_id_error.dart';
import 'package:pochi_trim/data/model/work_log.dart';
import 'package:pochi_trim/data/repository/work_log_repository.dart';
import 'package:pochi_trim/data/service/auth_service.dart';
import 'package:pochi_trim/data/service/system_service.dart';
import 'package:pochi_trim/ui/root_presenter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'work_log_service.g.dart';

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

  /// デバウンス閾値（ミリ秒）
  static const _debounceThresholdMilliseconds = 3000;

  final WorkLogRepository workLogRepository;
  final AuthService authService;
  final String currentHouseId;
  final SystemService systemService;
  final Ref ref;

  /// 各家事の最終登録時刻を追跡するMap（連打防止用）
  final Map<String, DateTime> _lastRegistrationTimes = {};

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
    final lastRegistrationTime = _lastRegistrationTimes[houseWorkId];

    if (lastRegistrationTime != null) {
      final timeDifference = now.difference(lastRegistrationTime);
      if (timeDifference.inMilliseconds < _debounceThresholdMilliseconds) {
        // 3秒以内の連続登録は無視
        return false;
      }
    }

    final userProfile = await ref.read(currentUserProfileProvider.future);
    if (userProfile == null) {
      return false;
    }

    onRequestAccepted?.call();

    _lastRegistrationTimes[houseWorkId] = now;

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
}
