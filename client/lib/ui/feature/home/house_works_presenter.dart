import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pochi_trim/data/model/app_session.dart';
import 'package:pochi_trim/data/model/delete_house_work_exception.dart'
    show DeleteHouseWorkException;
import 'package:pochi_trim/data/model/house_work.dart';
import 'package:pochi_trim/data/model/no_house_id_error.dart';
import 'package:pochi_trim/data/repository/house_work_repository.dart';
import 'package:pochi_trim/data/service/functions_service.dart';
import 'package:pochi_trim/ui/root_presenter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'house_works_presenter.g.dart';

// TODO(ide): 複数のPresenterに定義されているので、共通化する
@riverpod
Stream<List<HouseWork>> houseWorks(Ref ref) {
  final houseWorkRepository = ref.watch(houseWorkRepositoryProvider);

  return houseWorkRepository.getAll();
}

/// 現在の家の指定された家事を削除する
///
/// 削除に失敗した場合は[DeleteHouseWorkException]をスローします。
@riverpod
Future<void> deleteHouseWorkOfCurrentHouse(Ref ref, String houseWorkId) async {
  final appSession = ref.read(unwrappedCurrentAppSessionProvider);

  final String houseId;
  switch (appSession) {
    case AppSessionSignedIn(currentHouseId: final currentHouseId):
      houseId = currentHouseId;
    case AppSessionNotSignedIn():
      throw NoHouseIdError();
  }

  await ref.read(deleteHouseWorkProvider(houseId, houseWorkId).future);
}
