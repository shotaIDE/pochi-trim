import 'package:freezed_annotation/freezed_annotation.dart';

part 'add_house_work_result.freezed.dart';

@freezed
class AddHouseWorkResult with _$AddHouseWorkResult {
  const factory AddHouseWorkResult({
    required bool shouldShowTutorial,
  }) = _AddHouseWorkResult;
}
