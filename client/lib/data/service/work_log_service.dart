import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/data/model/app_session.dart';
import 'package:house_worker/data/model/no_house_id_error.dart';
import 'package:house_worker/data/model/work_log.dart';
import 'package:house_worker/data/repository/work_log_repository.dart';
import 'package:house_worker/data/service/auth_service.dart';
import 'package:house_worker/ui/root_presenter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'work_log_service.g.dart';

@riverpod
WorkLogService workLogService(Ref ref) {
  final appSession = ref.watch(unwrappedCurrentAppSessionProvider);
  final workLogRepository = ref.watch(workLogRepositoryProvider);
  final authService = ref.watch(authServiceProvider);

  switch (appSession) {
    case AppSessionSignedIn(currentHouseId: final currentHouseId):
      return WorkLogService(
        workLogRepository: workLogRepository,
        authService: authService,
        currentHouseId: currentHouseId,
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
    required this.ref,
  });

  final WorkLogRepository workLogRepository;
  final AuthService authService;
  final String currentHouseId;
  final Ref ref;

  Future<bool> recordWorkLog({required String houseWorkId}) async {
    final userProfile = await ref.read(currentUserProfileProvider.future);
    if (userProfile == null) {
      return false;
    }

    final workLog = WorkLog(
      id: '', // 新規登録のため空文字列
      houseWorkId: houseWorkId,
      completedAt: DateTime.now(),
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
