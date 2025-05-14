import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/data/model/work_log.dart';
import 'package:house_worker/data/repository/work_log_repository.dart';

// タイトルでワークログを検索するプロバイダー
final FutureProviderFamily<List<WorkLog>, String> workLogsByTitleProvider =
    FutureProvider.family<List<WorkLog>, String>((ref, title) {
      final workLogRepository = ref.watch(workLogRepositoryProvider);

      return workLogRepository.getWorkLogsByTitle(title);
    });

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

  // ワークログを削除する
  Future<void> deleteWorkLog(WorkLog workLog) async {
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
  }

  // 削除を取り消す
  Future<void> undoDelete() async {
    final deletedWorkLog = ref.read(deletedWorkLogProvider);
    if (deletedWorkLog != null) {
      // ワークログを復元
      await workLogRepository.save(deletedWorkLog);

      // 状態をリセット
      ref.read(deletedWorkLogProvider.notifier).state = null;
      ref.read(undoDeleteTimerProvider.notifier).state = null;
    }
  }
}
