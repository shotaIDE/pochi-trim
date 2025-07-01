import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pochi_trim/data/model/generate_my_house_result.dart';

part 'generate_my_house_result_functions.freezed.dart';
part 'generate_my_house_result_functions.g.dart';

@freezed
abstract class GenerateMyHouseResultFunctions
    with _$GenerateMyHouseResultFunctions {
  const factory GenerateMyHouseResultFunctions({
    required String houseDocId,
    required bool isNewHouse,
  }) = _GenerateMyHouseResultFunctions;

  factory GenerateMyHouseResultFunctions.fromJson(Map<String, dynamic> json) =>
      _$GenerateMyHouseResultFunctionsFromJson(json);

  GenerateMyHouseResult toGenerateMyHouseResult() {
    return GenerateMyHouseResult(
      houseId: houseDocId,
      isNewHouse: isNewHouse,
    );
  }
}
