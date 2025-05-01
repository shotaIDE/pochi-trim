import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/models/no_house_id_error.dart';
import 'package:house_worker/models/work_log.dart';
import 'package:house_worker/repositories/work_log_repository.dart';
import 'package:house_worker/services/auth_service.dart';
import 'package:house_worker/services/house_id_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'work_log_service.g.dart';

@riverpod
Future<WorkLogService> workLogService(Ref ref) async {
  final workLogRepository = await ref.watch(workLogRepositoryProvider.future);
  final authService = ref.watch(authServiceProvider);
  final houseId = await ref.watch(currentHouseIdProvider.future);
  if (houseId == null) {
    throw NoHouseIdError();
  }

  return WorkLogService(
    workLogRepository: workLogRepository,
    authService: authService,
    currentHouseId: houseId,
    ref: ref,
  );
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

  /// 家事ログを現在時刻で直接登録する
  ///
  /// [context] - BuildContext
  /// [houseWorkId] - 家事ID
  /// 成功時はtrue、失敗時はfalseを返す
  Future<bool> recordWorkLog(BuildContext context, String houseWorkId) async {
    // 現在のユーザーを取得
    final currentUser = authService.currentUser;
    if (currentUser == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('ユーザー情報が取得できませんでした')));
      }
      return false;
    }

    // 新しい家事ログを作成
    final workLog = WorkLog(
      id: '', // 新規登録のため空文字列
      houseWorkId: houseWorkId,
      completedAt: DateTime.now(), // 現在時刻
      completedBy: currentUser.uid,
    );

    try {
      // 家事ログを保存
      await workLogRepository.save(workLog);

      // 成功メッセージを表示
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('家事ログを記録しました')));
      }

      return true;
    } on Exception catch (e) {
      // エラー時の処理
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('エラーが発生しました: $e')));
      }
      return false;
    }
  }
}
