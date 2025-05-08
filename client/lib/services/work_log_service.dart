import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/models/no_house_id_error.dart';
import 'package:house_worker/models/work_log.dart';
import 'package:house_worker/repositories/work_log_repository.dart';
import 'package:house_worker/root_app_session.dart';
import 'package:house_worker/root_presenter.dart';
import 'package:house_worker/services/auth_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'work_log_service.g.dart';

@riverpod
WorkLogService workLogService(Ref ref) {
  final appSession = ref.watch(rootAppInitializedProvider);
  final workLogRepository = ref.watch(workLogRepositoryProvider);
  final authService = ref.watch(authServiceProvider);

  switch (appSession) {
    case final AppSessionSignedIn signedInSession:
      final houseId = signedInSession.currentHouseId;

      return WorkLogService(
        workLogRepository: workLogRepository,
        authService: authService,
        currentHouseId: houseId,
        ref: ref,
      );
    case AppSessionNotSignedIn _:
      throw NoHouseIdError();
    case AppSessionLoading _:
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
