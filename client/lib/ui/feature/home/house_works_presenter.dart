import 'package:pochi_trim/data/model/house_work.dart';
import 'package:pochi_trim/data/repository/house_work_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'house_works_presenter.g.dart';

// TODO(ide): 複数のPresenterに定義されているので、共通化する
@riverpod
Stream<List<HouseWork>> houseWorks(Ref ref) {
  final houseWorkRepository = ref.watch(houseWorkRepositoryProvider);

  return houseWorkRepository.getAll();
}
