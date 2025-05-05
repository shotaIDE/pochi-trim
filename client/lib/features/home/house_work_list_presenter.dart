import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/models/house_work.dart';
import 'package:house_worker/repositories/house_work_repository.dart';
import 'package:house_worker/services/work_log_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'house_work_list_presenter.g.dart';

// TODO(ide): 複数のPresenterに定義されているので、共通化する
@riverpod
Stream<List<HouseWork>> houseWorks(Ref ref) {
  final houseWorkRepository = ref.watch(houseWorkRepositoryProvider);

  return houseWorkRepository.getAll();
}

@riverpod
Future<bool> onCompleteHouseWorkTappedResult(Ref ref, HouseWork houseWork) {
  final workLogService = ref.read(workLogServiceProvider);

  return workLogService.recordWorkLog(houseWorkId: houseWork.id);
}

@riverpod
Future<bool> deleteHouseWork(Ref ref, String houseWorkId) {
  final houseWorkRepository = ref.read(houseWorkRepositoryProvider);

  return houseWorkRepository.delete(houseWorkId);
}
