import 'package:freezed_annotation/freezed_annotation.dart';

part 'bar_chart_touched_position.freezed.dart';

@freezed
abstract class BarChartTouchedPosition with _$BarChartTouchedPosition {
  const factory BarChartTouchedPosition({
    /// X軸の値
    required int groupIndex,

    /// X軸の値におけるサブの値
    required int rodDataIndex,

    /// 積み上げ棒グラフにおける位置番号
    required int stackItemIndex,
  }) = _BarChartTouchedPosition;
}
