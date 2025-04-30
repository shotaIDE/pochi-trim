import 'package:freezed_annotation/freezed_annotation.dart';

part 'generate_my_house_result.freezed.dart';
part 'generate_my_house_result.g.dart';

@freezed
abstract class GenerateMyHouseResult with _$GenerateMyHouseResult {
  const factory GenerateMyHouseResult({required String houseDocId}) =
      _GenerateMyHouseResult;

  factory GenerateMyHouseResult.fromJson(Map<String, dynamic> json) =>
      _$GenerateMyHouseResultFromJson(json);
}
