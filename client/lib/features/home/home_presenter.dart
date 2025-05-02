import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/models/house_work.dart';
import 'package:house_worker/models/work_log.dart';
import 'package:house_worker/repositories/house_work_repository.dart';
import 'package:house_worker/repositories/work_log_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_presenter.g.dart';

@riverpod
Stream<List<WorkLog>> completedWorkLogs(Ref ref) {
  return _completedWorkLogsFilePrivate(ref);
}

@riverpod
class HouseWorksSortedByMostFrequentlyUsed
    extends _$HouseWorksSortedByMostFrequentlyUsed {
  List<HouseWork>? _cachedSortedHouseWorksByCompletionCount;

  @override
  Stream<List<HouseWork>> build() {
    if (_cachedSortedHouseWorksByCompletionCount != null) {
      return Stream.value(_cachedSortedHouseWorksByCompletionCount!);
    }

    final houseWorksAsync = ref.watch(_houseWorksFilePrivateProvider);
    final completedWorkLogsAsync = ref.watch(
      _completedWorkLogsFilePrivateProvider,
    );

    final houseWorks = houseWorksAsync.whenOrNull(
      data: (houseWorks) => houseWorks,
    );
    final completedWorkLogs = completedWorkLogsAsync.whenOrNull(
      data: (completedWorkLogs) => completedWorkLogs,
    );
    if (houseWorks == null || completedWorkLogs == null) {
      return const Stream.empty();
    }

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

    _cachedSortedHouseWorksByCompletionCount =
        sortedHouseWorksByCompletionCount;

    return Stream.value(sortedHouseWorksByCompletionCount);
  }
}

@riverpod
Stream<List<HouseWork>> _houseWorksFilePrivate(Ref ref) {
  final houseWorkRepositoryAsync = ref.watch(houseWorkRepositoryProvider);

  return houseWorkRepositoryAsync.maybeWhen(
    data: (repository) => repository.getAll(),
    orElse: Stream.empty,
  );
}

@riverpod
Stream<List<WorkLog>> _completedWorkLogsFilePrivate(Ref ref) {
  final workLogRepositoryAsync = ref.watch(workLogRepositoryProvider);

  return workLogRepositoryAsync.maybeWhen(
    data: (repository) => repository.getCompletedWorkLogs(),
    orElse: Stream.empty,
  );
}
