import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/data/model/app_session.dart';
import 'package:house_worker/data/model/house_work.dart';
import 'package:house_worker/data/model/max_house_work_limit_exceeded_exception.dart';
import 'package:house_worker/data/repository/house_work_repository.dart';
import 'package:house_worker/ui/root_presenter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'add_house_work_presenter.g.dart';

@riverpod
Future<String> saveHouseWorkResult(Ref ref, HouseWork houseWork) async {
  final appSession = ref.watch(unwrappedCurrentAppSessionProvider);

  final bool isPro;
  switch (appSession) {
    case AppSessionSignedIn():
      isPro = appSession.isPro;
    case AppSessionNotSignedIn():
      isPro = false;
  }

  if (!isPro) {
    final houseWorks = await ref.read(houseWorkRepositoryProvider).getAllOnce();
    if (houseWorks.length >= 10) {
      throw MaxHouseWorkLimitExceededException();
    }
  }

  return ref.read(houseWorkRepositoryProvider).save(houseWork);
}
