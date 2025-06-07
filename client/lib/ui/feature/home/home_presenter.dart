import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pochi_trim/data/model/house_work.dart';
import 'package:pochi_trim/data/model/work_log.dart';
import 'package:pochi_trim/data/repository/house_work_repository.dart';
import 'package:pochi_trim/data/repository/work_log_repository.dart';
import 'package:pochi_trim/data/service/system_service.dart';
import 'package:pochi_trim/data/service/work_log_service.dart';
import 'package:pochi_trim/ui/feature/home/work_log_included_house_work.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_presenter.g.dart';

@riverpod
Future<List<HouseWork>> houseWorksSortedByMostFrequentlyUsed(Ref ref) async {
  final houseWorks = await ref.watch(_houseWorksFilePrivateProvider.future);
  final completedWorkLogs = await ref.watch(
    _completedWorkLogsFilePrivateProvider.future,
  );

  final completionCountOfHouseWorks = <HouseWork, int>{};

  for (final houseWork in houseWorks) {
    final completionCount = completedWorkLogs
        .where((workLog) => workLog.houseWorkId == houseWork.id)
        .length;

    completionCountOfHouseWorks[houseWork] = completionCount;
  }

  final sortedHouseWorksByCompletionCount = completionCountOfHouseWorks.entries
      .sortedBy((entry) => entry.value)
      .reversed
      .map((entry) => entry.key)
      .toList();

  return sortedHouseWorksByCompletionCount;
}

@riverpod
Future<bool> onCompleteHouseWorkButtonTappedResult(
  Ref ref,
  HouseWork houseWork,
) {
  final workLogService = ref.read(workLogServiceProvider);
  final systemService = ref.read(systemServiceProvider);

  return workLogService.recordWorkLog(
    houseWorkId: houseWork.id,
    onRequestAccepted: systemService.doHapticFeedbackActionReceived,
  );
}

@riverpod
Future<bool> onDuplicateWorkLogButtonTappedResult(
  Ref ref,
  WorkLogIncludedHouseWork workLogIncludedHouseWork,
) {
  final workLogService = ref.read(workLogServiceProvider);
  final systemService = ref.read(systemServiceProvider);

  return workLogService.recordWorkLog(
    houseWorkId: workLogIncludedHouseWork.houseWork.id,
    onRequestAccepted: systemService.doHapticFeedbackActionReceived,
  );
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
