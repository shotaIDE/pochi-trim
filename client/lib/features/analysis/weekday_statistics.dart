import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:house_worker/features/analysis/weekday_frequency.dart';
import 'package:house_worker/models/house_work.dart';

part 'weekday_statistics.freezed.dart';

@freezed
abstract class WeekdayStatistics with _$WeekdayStatistics {
  const factory WeekdayStatistics({
    required List<WeekdayFrequency> weekdayFrequencies,
    required List<HouseWorkLegends> houseWorkLegends,
  }) = _WeekdayStatistics;
}

@freezed
abstract class HouseWorkLegends with _$HouseWorkLegends {
  const factory HouseWorkLegends({
    required HouseWork houseWork,
    required Color color,
    required bool isVisible,
  }) = _HouseWorkLegends;
}
