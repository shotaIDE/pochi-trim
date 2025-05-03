import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:house_worker/features/analysis/analysis_screen.dart';
import 'package:house_worker/features/analysis/weekday_frequency.dart';
import 'package:house_worker/models/house_work.dart';

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
