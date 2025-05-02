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

  final sortedHouseWorksByCompletionCount =
      completionCountOfHouseWorks.entries
          .sortedBy((entry) => entry.value)
          .reversed
          .map((entry) => entry.key)
          .toList();

  return sortedHouseWorksByCompletionCount;
}
