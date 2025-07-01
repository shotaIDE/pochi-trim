import 'package:freezed_annotation/freezed_annotation.dart';

part 'generate_my_house_result.freezed.dart';

@freezed
abstract class GenerateMyHouseResult with _$GenerateMyHouseResult {
  const factory GenerateMyHouseResult({
    required String houseId,

    /// 家が新規に作成されたかどうか
    required bool created,
  }) = _GenerateMyHouseResult;
}
