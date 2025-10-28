import 'package:pochi_trim/data/model/no_house_id_error.dart';
import 'package:pochi_trim/data/model/preference_key.dart';
import 'package:pochi_trim/data/service/preference_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'house_repository.g.dart';

@riverpod
class CurrentHouseId extends _$CurrentHouseId {
  @override
  Future<String?> build() async {
    final preferenceService = ref.read(preferenceServiceProvider);

    final houseId = await preferenceService.getString(
      PreferenceKey.currentHouseId,
    );
    return houseId;
  }

  Future<void> setId(String houseId) async {
    final preferenceService = ref.read(preferenceServiceProvider);

    await preferenceService.setString(
      PreferenceKey.currentHouseId,
      value: houseId,
    );

    state = AsyncValue.data(houseId);
  }

  Future<void> removeId() async {
    final preferenceService = ref.read(preferenceServiceProvider);

    await preferenceService.remove(PreferenceKey.currentHouseId);

    state = const AsyncValue.data(null);
  }
}

@riverpod
String unwrappedCurrentHouseId(Ref ref) {
  final houseIdAsync = ref.watch(currentHouseIdProvider);
  final houseId = houseIdAsync.whenOrNull(
    data: (data) => data,
  );
  if (houseId == null) {
    throw NoHouseIdError();
  }

  return houseId;
}
