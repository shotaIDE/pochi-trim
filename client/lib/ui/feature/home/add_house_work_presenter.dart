import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pochi_trim/data/model/app_session.dart';
import 'package:pochi_trim/data/model/max_house_work_limit_exceeded_exception.dart';
import 'package:pochi_trim/data/repository/dao/add_house_work_args.dart';
import 'package:pochi_trim/data/repository/house_work_repository.dart';
import 'package:pochi_trim/ui/root_presenter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'add_house_work_presenter.g.dart';

@riverpod
Future<String> saveHouseWorkResult(Ref ref, AddHouseWorkArgs args) async {
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

  return ref.read(houseWorkRepositoryProvider).add(args);
}
