import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'house_id_provider.g.dart';

@riverpod
class CurrentHouseId extends _$CurrentHouseId {
  @override
  Future<String?> build() async {
    // TODO(ide): 適切な値に置き換える
    return 'default-house-id';
  }

  void setHouseId(String houseId) {
    state = AsyncValue.data(houseId);
  }
}
