import 'package:freezed_annotation/freezed_annotation.dart';

part 'generate_my_house_result_functions.freezed.dart';
part 'generate_my_house_result_functions.g.dart';

@freezed
abstract class GenerateMyHouseResultFunctions
    with _$GenerateMyHouseResultFunctions {
  const factory GenerateMyHouseResultFunctions({required String houseDocId}) =
      _GenerateMyHouseResultFunctions;

  factory GenerateMyHouseResultFunctions.fromJson(Map<String, dynamic> json) =>
      _$GenerateMyHouseResultFunctionsFromJson(json);
}
