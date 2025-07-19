import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pochi_trim/data/model/update_work_log_exception.dart';
import 'package:pochi_trim/data/repository/work_log_repository.dart';
import 'package:pochi_trim/data/service/error_report_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'edit_work_log_presenter.g.dart';

@riverpod
Future<void> updateWorkLogDateTime(
  Ref ref,
  String workLogId,
  DateTime newDateTime,
) async {
  final workLogRepository = ref.read(workLogRepositoryProvider);
  final errorReportService = ref.read(errorReportServiceProvider);

  try {
    await workLogRepository.updateDateTime(workLogId, newDateTime);
  } on Exception catch (e, stack) {
    await errorReportService.recordError(e, stack);
    throw const UpdateWorkLogException();
  }
}
