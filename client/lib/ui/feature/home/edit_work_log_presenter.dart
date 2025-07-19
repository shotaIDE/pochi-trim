import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pochi_trim/data/model/update_work_log_exception.dart';
import 'package:pochi_trim/data/repository/work_log_repository.dart';
import 'package:pochi_trim/data/service/system_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'edit_work_log_presenter.g.dart';

@riverpod
Future<void> updateWorkLogDateTime(
  Ref ref,
  String workLogId,
  DateTime newDateTime,
) async {
  final systemService = ref.read(systemServiceProvider);
  final now = systemService.getCurrentDateTime();
  if (newDateTime.isAfter(now)) {
    throw const UpdateWorkLogException.futureDateTime();
  }

  final workLogRepository = ref.read(workLogRepositoryProvider);
  await workLogRepository.updateDateTime(workLogId, newDateTime);
}
