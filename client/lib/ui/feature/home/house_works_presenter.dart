import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/data/model/house_work.dart';
import 'package:house_worker/data/repository/house_work_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'house_works_presenter.g.dart';

// TODO(ide): 複数のPresenterに定義されているので、共通化する
@riverpod
Stream<List<HouseWork>> houseWorks(Ref ref) {
  final houseWorkRepository = ref.watch(houseWorkRepositoryProvider);

  return houseWorkRepository.getAll();
}

@riverpod
Future<bool> deleteHouseWork(Ref ref, String houseWorkId) {
  final houseWorkRepository = ref.read(houseWorkRepositoryProvider);

  return houseWorkRepository.delete(houseWorkId);
}
