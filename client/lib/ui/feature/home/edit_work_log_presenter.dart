import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pochi_trim/data/model/update_work_log_exception.dart';
import 'package:pochi_trim/data/repository/work_log_repository.dart';
import 'package:pochi_trim/data/service/system_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'edit_work_log_presenter.g.dart';

@riverpod
Future<void> updateCompletedAtOfWorkLog(
  Ref ref,
  String workLogId,
  DateTime completedAt,
) async {
  final systemService = ref.read(systemServiceProvider);
  final now = systemService.getCurrentDateTime();
  if (completedAt.isAfter(now)) {
    throw const UpdateWorkLogException.futureDateTime();
  }

  final workLogRepository = ref.read(workLogRepositoryProvider);
  await workLogRepository.updateCompletedAt(
    workLogId,
    completedAt: completedAt,
  );
}
