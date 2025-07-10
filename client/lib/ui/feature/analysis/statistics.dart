import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pochi_trim/data/model/house_work.dart';
import 'package:pochi_trim/ui/feature/analysis/frequency.dart';
import 'package:pochi_trim/ui/feature/analysis/weekday_frequency.dart';

part 'statistics.freezed.dart';

@freezed
abstract class WeekdayStatistics with _$WeekdayStatistics {
  const factory WeekdayStatistics({
    required List<WeekdayFrequency> weekdayFrequencies,
    required List<HouseWorkLegends> houseWorkLegends,
  }) = _WeekdayStatistics;
}

@freezed
abstract class TimeSlotStatistics with _$TimeSlotStatistics {
  const factory TimeSlotStatistics({
    required List<TimeSlotFrequency> timeSlotFrequencies,
    required List<HouseWorkLegends> houseWorkLegends,
  }) = _TimeSlotStatistics;
}

@freezed
abstract class HouseWorkLegends with _$HouseWorkLegends {
  const factory HouseWorkLegends({
    required HouseWork houseWork,
    required Color color,
    required bool isVisible,
  }) = _HouseWorkLegends;
}
