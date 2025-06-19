import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pochi_trim/data/model/delete_work_log_exception.dart';
import 'package:pochi_trim/data/model/work_log.dart';
import 'package:pochi_trim/data/repository/work_log_repository.dart';

// 削除されたワークログを一時的に保持するプロバイダー
final deletedWorkLogProvider = StateProvider<WorkLog?>((ref) => null);

// ワークログ削除の取り消しタイマーを管理するプロバイダー
final undoDeleteTimerProvider = StateProvider<int?>((ref) => null);

// ワークログ削除処理を行うプロバイダー
final Provider<WorkLogDeletionNotifier> workLogDeletionProvider = Provider((
  ref,
) {
  final workLogRepository = ref.watch(workLogRepositoryProvider);

  return WorkLogDeletionNotifier(
    workLogRepository: workLogRepository,
    ref: ref,
  );
});

class WorkLogDeletionNotifier {
  WorkLogDeletionNotifier({required this.workLogRepository, required this.ref});
  final WorkLogRepository workLogRepository;
  final Ref ref;

  /// ワークログを削除し、5秒間の取り消し期間を提供する
  ///
  /// Throws:
  ///   - [DeleteWorkLogException] - Firebase削除処理に失敗した場合
  Future<void> deleteWorkLog(WorkLog workLog) async {
    try {
      // 削除前にワークログを保存
      ref.read(deletedWorkLogProvider.notifier).state = workLog;

      // ワークログを削除
      await workLogRepository.delete(workLog.id);

      // 既存のタイマーがあればキャンセル
      final existingTimerId = ref.read(undoDeleteTimerProvider);
      if (existingTimerId != null) {
        Future.delayed(Duration.zero, () {
          ref.invalidate(undoDeleteTimerProvider);
        });
      }

      // 5秒後に削除を確定するタイマーを設定
      final timerId = DateTime.now().millisecondsSinceEpoch;
      ref.read(undoDeleteTimerProvider.notifier).state = timerId;

      Future.delayed(const Duration(seconds: 5), () {
        final currentTimerId = ref.read(undoDeleteTimerProvider);
        if (currentTimerId == timerId) {
          // タイマーが変更されていなければ、削除を確定
          ref.read(deletedWorkLogProvider.notifier).state = null;
          ref.read(undoDeleteTimerProvider.notifier).state = null;
        }
      });
    } on DeleteWorkLogException {
      // 削除に失敗した場合は例外を再スロー
      rethrow;
    }
  }

  /// 削除されたワークログを復元する
  Future<void> undoDelete() async {
    final deletedWorkLog = ref.read(deletedWorkLogProvider);
    if (deletedWorkLog != null) {
      // ワークログを復元
      await workLogRepository.update(deletedWorkLog);

      // 状態をリセット
      ref.read(deletedWorkLogProvider.notifier).state = null;
      ref.read(undoDeleteTimerProvider.notifier).state = null;
    }
  }
}
