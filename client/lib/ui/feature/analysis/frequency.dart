import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pochi_trim/data/model/house_work.dart';

part 'frequency.freezed.dart';

@freezed
abstract class HouseWorkFrequency with _$HouseWorkFrequency {
  const factory HouseWorkFrequency({
    required HouseWork houseWork,
    required int count,
    @Default(Colors.grey) Color color,
  }) = _HouseWorkFrequency;
}

@freezed
abstract class TimeSlotFrequency with _$TimeSlotFrequency {
  const factory TimeSlotFrequency({
    required String timeSlot,
    required List<HouseWorkFrequency> houseWorkFrequencies,
    required int totalCount,
  }) = _TimeSlotFrequency;
}
