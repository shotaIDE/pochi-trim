import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'house_id_provider.g.dart';

@riverpod
class CurrentHouseId extends _$CurrentHouseId {
  @override
  String? build() {
    return null;
  }

  // ignore: use_setters_to_change_properties
  void setHouseId(String houseId) {
    state = houseId;
  }
}
