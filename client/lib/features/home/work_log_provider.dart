import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/features/home/work_log_add_screen.dart'; // currentHouseIdProviderをインポート
import 'package:house_worker/models/work_log.dart';
import 'package:house_worker/repositories/work_log_repository.dart';

// 完了済みワークログの一覧を提供するプロバイダー
final completedWorkLogsProvider = StreamProvider<List<WorkLog>>((ref) {
  final workLogRepository = ref.watch(workLogRepositoryProvider);
  final houseId = ref.watch(currentHouseIdProvider);
  return workLogRepository.getCompletedWorkLogs(houseId);
});

// タイトルでワークログを検索するプロバイダー
final workLogsByTitleProvider = FutureProvider.family<List<WorkLog>, String>((
  ref,
  title,
) async {
  final workLogRepository = ref.watch(workLogRepositoryProvider);
  final houseId = ref.watch(currentHouseIdProvider);
  return await workLogRepository.getWorkLogsByTitle(houseId, title);
});

// 削除されたワークログを一時的に保持するプロバイダー
final deletedWorkLogProvider = StateProvider<WorkLog?>((ref) => null);

// ワークログ削除の取り消しタイマーを管理するプロバイダー
final undoDeleteTimerProvider = StateProvider<int?>((ref) => null);

// ワークログ削除処理を行うプロバイダー
final workLogDeletionProvider = Provider((ref) {
  final workLogRepository = ref.watch(workLogRepositoryProvider);

  return WorkLogDeletionNotifier(
    workLogRepository: workLogRepository,
    ref: ref,
  );
});

class WorkLogDeletionNotifier {
  final WorkLogRepository workLogRepository;
  final Ref ref;

  WorkLogDeletionNotifier({required this.workLogRepository, required this.ref});

  // ワークログを削除する
  Future<void> deleteWorkLog(WorkLog workLog) async {
    // 削除前にワークログを保存
    ref.read(deletedWorkLogProvider.notifier).state = workLog;

    // ハウスIDを取得
    final houseId = ref.read(currentHouseIdProvider);

    // ワークログを削除
    await workLogRepository.delete(houseId, workLog.id);

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
      // ハウスIDを取得
      final houseId = ref.read(currentHouseIdProvider);

      // ワークログを復元
      await workLogRepository.save(houseId, deletedWorkLog);

      // 状態をリセット
      ref.read(deletedWorkLogProvider.notifier).state = null;
      ref.read(undoDeleteTimerProvider.notifier).state = null;
    }
  }
}
