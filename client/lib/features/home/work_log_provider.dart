import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/models/house_work.dart';
import 'package:house_worker/models/work_log.dart';
import 'package:house_worker/repositories/house_work_repository.dart';
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

final houseWorksSortedByMostFrequentlyUsedProvider =
    StreamProvider<List<HouseWork>>((ref) {
      final houseWorksAsync = ref.watch(houseWorksProvider);
      final completedWorkLogs = ref.watch(completedWorkLogsProvider);

      return houseWorksAsync.when(
        data: (houseWorks) {
          final latestUsedTimeForHouseWorks = <HouseWork, DateTime>{};
          for (final houseWork in houseWorks) {
            latestUsedTimeForHouseWorks[houseWork] = houseWork.createdAt;
          }

          completedWorkLogs.maybeWhen(
            data: (workLogs) {
              for (final workLog in workLogs) {
                final targetHouseWork = houseWorks.firstWhereOrNull(
                  (houseWork) => houseWork.id == workLog.houseWorkId,
                );
                if (targetHouseWork == null) {
                  continue;
                }

                final currentLatestUsedTime =
                    latestUsedTimeForHouseWorks[targetHouseWork];
                if (currentLatestUsedTime == null) {
                  latestUsedTimeForHouseWorks[targetHouseWork] =
                      workLog.completedAt;
                  continue;
                }

                if (currentLatestUsedTime.isAfter(workLog.completedAt)) {
                  continue;
                }

                latestUsedTimeForHouseWorks[targetHouseWork] =
                    workLog.completedAt;
              }
            },
            orElse: () {},
          );

          return Stream.value(
            latestUsedTimeForHouseWorks.entries
                .sortedBy((entry) => entry.value)
                .reversed
                .map((entry) => entry.key)
                .toList(),
          );
        },
        error: (error, stack) => Stream.error(error),
        loading: Stream.empty,
      );
    });

final houseWorksProvider = StreamProvider<List<HouseWork>>((ref) {
  final houseWorkRepository = ref.watch(houseWorkRepositoryProvider);
  final houseId = ref.watch(currentHouseIdProvider);

  return houseWorkRepository
      .getAll(houseId: houseId)
      .map((houseWorks) => houseWorks.toList());
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
