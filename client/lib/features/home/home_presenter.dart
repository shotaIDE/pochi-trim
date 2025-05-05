import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/features/home/work_log_included_house_work.dart';
import 'package:house_worker/models/house_work.dart';
import 'package:house_worker/models/work_log.dart';
import 'package:house_worker/repositories/house_work_repository.dart';
import 'package:house_worker/repositories/work_log_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_presenter.g.dart';

@riverpod
Future<List<WorkLogIncludedHouseWork>> workLogsIncludedHouseWork(
  Ref ref,
) async {
  final houseWorksFuture = ref.watch(_houseWorksFilePrivateProvider.future);
  final workLogsFuture = ref.watch(
    _completedWorkLogsFilePrivateProvider.future,
  );

  final houseWorks = await houseWorksFuture;
  final workLogs = await workLogsFuture;

  final workLogsForDisplay =
      workLogs
          .map((workLog) {
            final houseWork = houseWorks.firstWhereOrNull(
              (houseWork) => houseWork.id == workLog.houseWorkId,
            );

            if (houseWork == null) {
              return null;
            }

            return WorkLogIncludedHouseWork.fromWorkLogAndHouseWork(
              workLog: workLog,
              houseWork: houseWork,
            );
          })
          .nonNulls
          .toList();

  return workLogsForDisplay;
}

@riverpod
Future<List<HouseWork>> houseWorksSortedByMostFrequentlyUsed(Ref ref) async {
  final houseWorks = await ref.watch(_houseWorksFilePrivateProvider.future);
  final completedWorkLogs = await ref.watch(
    _completedWorkLogsFilePrivateProvider.future,
  );

  final completionCountOfHouseWorks = <HouseWork, int>{};

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

@riverpod
Stream<List<HouseWork>> _houseWorksFilePrivate(Ref ref) {
  final houseWorkRepository = ref.watch(houseWorkRepositoryProvider);

  return houseWorkRepository.getAll();
}

@riverpod
Stream<List<WorkLog>> _completedWorkLogsFilePrivate(Ref ref) {
  final workLogRepository = ref.watch(workLogRepositoryProvider);

  return workLogRepository.getCompletedWorkLogs();
}
