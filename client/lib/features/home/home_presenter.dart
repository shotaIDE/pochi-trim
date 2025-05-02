import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/features/home/work_log_provider.dart';
import 'package:house_worker/models/house_work.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_presenter.g.dart';

@riverpod
Future<List<HouseWork>> houseWorksSortedByMostFrequentlyUsed(Ref ref) async {
  final houseWorks = await ref.watch(houseWorksProvider.future);
  final completedWorkLogs = await ref.watch(completedWorkLogsProvider.future);

  // 家事ごとの完了回数をカウント
  final completionCountByHouseWork = <HouseWork, int>{};
  // 完了されたことがある家事と完了されたことがない家事を分ける
  final completedHouseWorks = <HouseWork>[];
  final neverCompletedHouseWorks = <HouseWork>[];

  // 初期化：すべての家事の完了回数を0に設定
  for (final houseWork in houseWorks) {
    completionCountByHouseWork[houseWork] = 0;
  }

  // 完了ログを走査して、各家事の完了回数をカウント
  for (final workLog in completedWorkLogs) {
    final targetHouseWork = houseWorks.firstWhereOrNull(
      (houseWork) => houseWork.id == workLog.houseWorkId,
    );
    if (targetHouseWork == null) {
      continue;
    }

    completionCountByHouseWork[targetHouseWork] =
        (completionCountByHouseWork[targetHouseWork] ?? 0) + 1;
  }

  // 完了されたことがある家事と完了されたことがない家事を分ける
  for (final entry in completionCountByHouseWork.entries) {
    if (entry.value > 0) {
      completedHouseWorks.add(entry.key);
    } else {
      neverCompletedHouseWorks.add(entry.key);
    }
  }

  // 1. 完了されたことがある家事を完了回数の多い順に並べる
  final sortedCompletedHouseWorks = completedHouseWorks.sortedBy(
    (houseWork) => -completionCountByHouseWork[houseWork]!,
  );

  // 2. 完了されたことがない家事を作成日時の新しい順に並べる
  final sortedNeverCompletedHouseWorks =
      neverCompletedHouseWorks
          .sortedBy((houseWork) => houseWork.createdAt)
          .reversed
          .toList();

  // 完了されたことがある家事の後に、完了されたことがない家事を追加
  return [...sortedCompletedHouseWorks, ...sortedNeverCompletedHouseWorks];
}
