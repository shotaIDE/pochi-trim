import 'package:flutter/material.dart';
import 'package:pochi_trim/data/model/house_work.dart';

// 家事ごとの頻度分析のためのデータクラス
class HouseWorkFrequency {
  HouseWorkFrequency({
    required this.houseWork,
    required this.count,
    // TODO(ide): デフォルト引数を廃止する
    this.color = Colors.grey,
  });

  final HouseWork houseWork;
  final int count;
  final Color color;
}

// 時間帯別の家事実行頻度のためのデータクラス
class TimeSlotFrequency {
  TimeSlotFrequency({
    required this.timeSlot,
    required this.houseWorkFrequencies,
    required this.totalCount,
  });
  final String timeSlot; // 時間帯の表示名（例：「0-3時」）
  final List<HouseWorkFrequency> houseWorkFrequencies; // その時間帯での家事ごとの実行回数
  final int totalCount; // その時間帯の合計実行回数
}
