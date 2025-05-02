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

  final latestUsedTimeOfHouseWorks = <HouseWork, DateTime>{};
  for (final houseWork in houseWorks) {
    latestUsedTimeOfHouseWorks[houseWork] = houseWork.createdAt;
  }

  for (final workLog in completedWorkLogs) {
    final targetHouseWork = houseWorks.firstWhereOrNull(
      (houseWork) => houseWork.id == workLog.houseWorkId,
    );
    if (targetHouseWork == null) {
      continue;
    }

    final currentLatestUsedTime = latestUsedTimeOfHouseWorks[targetHouseWork];
    if (currentLatestUsedTime == null) {
      latestUsedTimeOfHouseWorks[targetHouseWork] = workLog.completedAt;
      continue;
    }

    if (currentLatestUsedTime.isAfter(workLog.completedAt)) {
      continue;
    }

    latestUsedTimeOfHouseWorks[targetHouseWork] = workLog.completedAt;
  }

  return latestUsedTimeOfHouseWorks.entries
      .sortedBy((entry) => entry.value)
      .reversed
      .map((entry) => entry.key)
      .toList();
}
