import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/models/work_log.dart';
import 'package:house_worker/repositories/work_log_repository.dart';
import 'package:house_worker/services/house_id_provider.dart';

// 完了済みワークログの一覧を提供するプロバイダー
final completedWorkLogsProvider = StreamProvider<List<WorkLog>>((ref) {
  final workLogRepository = ref.watch(workLogRepositoryProvider);
  final houseId = ref.watch(currentHouseIdProvider);
  return workLogRepository.getCompletedWorkLogs(houseId);
});

// 特定の家事IDに関連するワークログを取得するプロバイダー
final FutureProviderFamily<List<WorkLog>, String>
workLogsByHouseWorkIdProvider = FutureProvider.family<List<WorkLog>, String>((
  ref,
  houseWorkId,
) {
  final workLogRepository = ref.watch(workLogRepositoryProvider);
  final houseId = ref.watch(currentHouseIdProvider);
  return workLogRepository.getWorkLogsByHouseWork(houseId, houseWorkId);
});

// タイトルでワークログを検索するプロバイダー
final FutureProviderFamily<List<WorkLog>, String> workLogsByTitleProvider =
    FutureProvider.family<List<WorkLog>, String>((ref, title) {
      final workLogRepository = ref.watch(workLogRepositoryProvider);
      final houseId = ref.watch(currentHouseIdProvider);
      return workLogRepository.getWorkLogsByTitle(houseId, title);
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

// よく完了されている家事ログを取得するプロバイダー
final frequentlyCompletedWorkLogsProvider = FutureProvider<List<WorkLog>>((
  ref,
) async {
  final workLogRepository = ref.watch(workLogRepositoryProvider);
  final houseId = ref.watch(currentHouseIdProvider);

  // 完了済みの家事ログを取得
  final completedLogs =
      await workLogRepository.getCompletedWorkLogs(houseId).first;

  // 家事IDごとに集計して、頻度の高い順にソート
  final houseWorkFrequency = <String, int>{};
  final latestLogByHouseWork = <String, WorkLog>{};

  for (final log in completedLogs) {
    houseWorkFrequency[log.houseWorkId] =
        (houseWorkFrequency[log.houseWorkId] ?? 0) + 1;

    // 各家事IDの最新のログを保持
    final existingLog = latestLogByHouseWork[log.houseWorkId];
    // completedAtがnullの場合を考慮
    final logCompletedAt = log.completedAt;
    final existingLogCompletedAt = existingLog?.completedAt;

    if (existingLog == null ||
        (existingLogCompletedAt == null ||
            logCompletedAt.isAfter(existingLogCompletedAt))) {
      latestLogByHouseWork[log.houseWorkId] = log;
    }
  }

  // 頻度順にソートされた家事IDのリスト
  final sortedHouseWorkIds =
      houseWorkFrequency.keys.toList()..sort(
        (a, b) => houseWorkFrequency[b]!.compareTo(houseWorkFrequency[a]!),
      );

  // 上位5件のログを返す（または全件数が5未満の場合はすべて）
  return sortedHouseWorkIds
      .take(5)
      .map((id) => latestLogByHouseWork[id]!)
      .toList();
});

class WorkLogDeletionNotifier {
  WorkLogDeletionNotifier({required this.workLogRepository, required this.ref});
  final WorkLogRepository workLogRepository;
  final Ref ref;

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
