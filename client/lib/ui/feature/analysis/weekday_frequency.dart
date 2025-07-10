// 曜日ごとの頻度分析のためのデータクラス
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pochi_trim/ui/feature/analysis/frequency.dart';
import 'package:pochi_trim/ui/feature/analysis/weekday.dart';

part 'weekday_frequency.freezed.dart';

@freezed
abstract class WeekdayFrequency with _$WeekdayFrequency {
  const factory WeekdayFrequency({
    required Weekday weekday,
    // その曜日での家事ごとの実行回数
    required List<HouseWorkFrequency> houseWorkFrequencies,
    required int totalCount,
  }) = _WeekdayFrequency;

  const WeekdayFrequency._();

  // fl_chartのBarChartRodData作成用のヘルパーメソッド
  BarChartRodData toBarChartRodData({
    required double width,
    required double x,
    required List<Color> colors,
  }) {
    // 家事の実行回数ごとにRodStackItemを作成
    final rodStackItems = <BarChartRodStackItem>[];

    double fromY = 0;
    for (var i = 0; i < houseWorkFrequencies.length; i++) {
      final item = houseWorkFrequencies[i];
      final toY = fromY + item.count;

      rodStackItems.add(
        BarChartRodStackItem(fromY, toY, colors[i % colors.length]),
      );

      fromY = toY;
    }

    return BarChartRodData(
      toY: totalCount.toDouble(),
      width: width,
      color: Colors.transparent,
      rodStackItems: rodStackItems,
      borderRadius: BorderRadius.zero,
    );
  }
}
