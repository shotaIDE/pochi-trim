import 'package:freezed_annotation/freezed_annotation.dart';

part 'bar_chart_touched_position.freezed.dart';

@freezed
abstract class BarChartTouchedPosition with _$BarChartTouchedPosition {
  const factory BarChartTouchedPosition({
    required int groupIndex,
    required int rodDataIndex,
    required int stackItemIndex,
  }) = _BarChartTouchedPosition;
}
