import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:house_worker/data/model/house_work.dart';
import 'package:house_worker/data/model/work_log.dart';

part 'work_log_included_house_work.freezed.dart';

@freezed
abstract class WorkLogIncludedHouseWork with _$WorkLogIncludedHouseWork {
  const factory WorkLogIncludedHouseWork({
    required String id,
    required HouseWork houseWork,
    required DateTime completedAt,
    required String completedBy,
  }) = _WorkLogIncludedHouseWork;

  const WorkLogIncludedHouseWork._();

  factory WorkLogIncludedHouseWork.fromWorkLogAndHouseWork({
    required WorkLog workLog,
    required HouseWork houseWork,
  }) {
    return WorkLogIncludedHouseWork(
      id: workLog.id,
      houseWork: houseWork,
      completedAt: workLog.completedAt,
      completedBy: workLog.completedBy,
    );
  }

  WorkLog toWorkLog() {
    return WorkLog(
      id: id,
      houseWorkId: houseWork.id,
      completedAt: completedAt,
      completedBy: completedBy,
    );
  }
}
