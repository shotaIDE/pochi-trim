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

  final completionCountOfHouseWorks = <HouseWork, int>{};
  final completedHouseWorks = <HouseWork>[];
  final neverCompletedHouseWorks = <HouseWork>[];

  for (final houseWork in houseWorks) {
    completionCountOfHouseWorks[houseWork] = 0;
  }

  for (final houseWork in houseWorks) {
    final completionCount =
        completedWorkLogs
            .where((workLog) => workLog.houseWorkId == houseWork.id)
            .length;

    completionCountOfHouseWorks[houseWork] = completionCount;
  }

  // 完了されたことがある家事と完了されたことがない家事を分ける
  for (final entry in completionCountOfHouseWorks.entries) {
    if (entry.value > 0) {
      completedHouseWorks.add(entry.key);
    } else {
      neverCompletedHouseWorks.add(entry.key);
    }
  }

  // 1. 完了されたことがある家事を完了回数の多い順に並べる
  final sortedCompletedHouseWorks = completedHouseWorks.sortedBy(
    (houseWork) => -completionCountOfHouseWorks[houseWork]!,
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
