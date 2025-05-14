import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/data/model/house_work.dart';
import 'package:house_worker/data/model/work_log.dart';
import 'package:house_worker/data/repository/house_work_repository.dart';
import 'package:house_worker/data/repository/work_log_repository.dart';
import 'package:house_worker/ui/feature/home/work_log_included_house_work.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'work_logs_presenter.g.dart';

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

// TODO(ide): 複数のPresenterに定義されているので、共通化する
@riverpod
Stream<List<HouseWork>> _houseWorksFilePrivate(Ref ref) {
  final houseWorkRepository = ref.watch(houseWorkRepositoryProvider);

  return houseWorkRepository.getAll();
}

// TODO(ide): 複数のPresenterに定義されているので、共通化する
@riverpod
Stream<List<WorkLog>> _completedWorkLogsFilePrivate(Ref ref) {
  final workLogRepository = ref.watch(workLogRepositoryProvider);

  return workLogRepository.getCompletedWorkLogs();
}
