import 'package:pochi_trim/data/model/preference_key.dart';
import 'package:pochi_trim/data/service/preference_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'house_repository.g.dart';

@riverpod
class HouseId extends _$HouseId {
  @override
  Future<String?> build() async {
    final preferenceService = ref.read(preferenceServiceProvider);

    final houseId = await preferenceService.getString(
      PreferenceKey.currentHouseId,
    );
    return houseId;
  }

  Future<void> setCurrent(String houseId) async {
    final preferenceService = ref.read(preferenceServiceProvider);

    await preferenceService.setString(
      PreferenceKey.currentHouseId,
      value: houseId,
    );

    state = AsyncValue.data(houseId);
  }
}
