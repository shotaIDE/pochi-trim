import 'package:house_worker/models/preference_key.dart';
import 'package:house_worker/services/preference_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'house_id_provider.g.dart';

@riverpod
class CurrentHouseId extends _$CurrentHouseId {
  @override
  Future<String?> build() async {
    final preferenceService = ref.watch(preferenceServiceProvider);

    final houseId =
        await preferenceService.getString(PreferenceKey.currentHouseId) ??
        // TODO(ide): 開発用。本番リリース時には削除する
        'default-house-id';

    return houseId;
  }

  // ignore: use_setters_to_change_properties
  Future<void> setHouseId(String houseId) async {
    final preferenceService = ref.read(preferenceServiceProvider);

    await preferenceService.setString(
      PreferenceKey.currentHouseId,
      value: houseId,
    );

    state = AsyncValue.data(houseId);
  }
}
