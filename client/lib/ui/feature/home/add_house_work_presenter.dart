import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pochi_trim/data/model/max_house_work_limit_exceeded_exception.dart';
import 'package:pochi_trim/data/model/preference_key.dart';
import 'package:pochi_trim/data/repository/dao/add_house_work_args.dart';
import 'package:pochi_trim/data/repository/house_work_repository.dart';
import 'package:pochi_trim/data/service/in_app_purchase_service.dart';
import 'package:pochi_trim/data/service/preference_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'add_house_work_presenter.g.dart';

@riverpod
Future<String> saveHouseWorkResult(Ref ref, AddHouseWorkArgs args) async {
  final isPro = await ref.watch(isProUserProvider.future);

  if (!isPro) {
    final houseWorks = await ref.read(houseWorkRepositoryProvider).getAllOnce();
    if (houseWorks.length >= 10) {
      throw MaxHouseWorkLimitExceededException();
    }
  }

  return ref.read(houseWorkRepositoryProvider).add(args);
}

@riverpod
Future<bool> shouldShowTutorial(Ref ref, AddHouseWorkArgs args) async {
  final houseWorks = await ref.read(houseWorkRepositoryProvider).getAllOnce();
  final isFirstHouseWork = houseWorks.isEmpty;

  if (!isFirstHouseWork) {
    return false;
  }

  final preferenceService = ref.read(preferenceServiceProvider);
  final hasShownTutorial = await preferenceService.getBool(
    PreferenceKey.hasShownFirstHouseWorkTutorial,
  );

  return hasShownTutorial != true;
}
