import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/features/analysis/analysis_screen.dart';
import 'package:house_worker/features/analysis/weekday_frequency.dart';
import 'package:house_worker/models/house_work.dart';
import 'package:house_worker/models/work_log.dart';
import 'package:house_worker/repositories/house_work_repository.dart';
import 'package:house_worker/repositories/work_log_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'analysis_presenter.g.dart';

@riverpod
class HouseWorkVisibilities extends _$HouseWorkVisibilities {
  @override
  Map<String, bool> build() {
    return {};
  }

  void toggle({required String houseWorkId}) {
    final newState = Map<String, bool>.from(state);

    newState[houseWorkId] = !(state[houseWorkId] ?? true);

    state = newState;
  }

  bool isVisible({required String houseWorkId}) {
    return state[houseWorkId] ?? true;
  }
}

@riverpod
Future<List<WorkLog>> filteredWorkLogs(Ref ref, int period) async {
  final workLogRepository = await ref.watch(workLogRepositoryProvider.future);

  final allWorkLogs = await workLogRepository.getAllOnce();

  // 現在時刻を取得
  final now = DateTime.now();

  // 期間によるフィルタリング
  switch (period) {
    case 0: // 今日
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay
          .add(const Duration(days: 1))
          .subtract(const Duration(microseconds: 1));
      return allWorkLogs
          .where(
            (log) =>
                log.completedAt.isAfter(startOfDay) &&
                log.completedAt.isBefore(endOfDay),
          )
          .toList();

    case 1: // 今週
      // 週の開始は月曜日、終了は日曜日とする
      final currentWeekday = now.weekday;
      final startOfWeek = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: currentWeekday - 1));
      final endOfWeek = startOfWeek
          .add(const Duration(days: 7))
          .subtract(const Duration(microseconds: 1));
      return allWorkLogs
          .where(
            (log) =>
                log.completedAt.isAfter(startOfWeek) &&
                log.completedAt.isBefore(endOfWeek),
          )
          .toList();

    case 2: // 今月
      final startOfMonth = DateTime(now.year, now.month);
      final endOfMonth =
          (now.month < 12)
              ? DateTime(now.year, now.month + 1)
              : DateTime(now.year + 1);
      final lastDayOfMonth = endOfMonth.subtract(
        const Duration(microseconds: 1),
      );
      return allWorkLogs
          .where(
            (log) =>
                log.completedAt.isAfter(startOfMonth) &&
                log.completedAt.isBefore(lastDayOfMonth),
          )
          .toList();

    default:
      return allWorkLogs;
  }
}

@riverpod
Future<List<WeekdayFrequency>> filteredWeekdayFrequencies(
  Ref ref, {
  required int period,
}) async {
  // フィルタリングされた家事ログのデータを待機
  final workLogs = await ref.watch(filteredWorkLogsProvider(period).future);
  final houseWorkRepository = await ref.watch(
    houseWorkRepositoryProvider.future,
  );
  final houseWorkVisibilities = ref.watch(houseWorkVisibilitiesProvider);

  // 曜日名の配列（インデックスは0が日曜日）
  final weekdayNames = ['日曜日', '月曜日', '火曜日', '水曜日', '木曜日', '金曜日', '土曜日'];

  // 曜日ごと、家事IDごとにグループ化して頻度をカウント
  final weekdayMap = <int, Map<String, int>>{};
  // 各曜日の初期化
  for (var i = 0; i < 7; i++) {
    weekdayMap[i] = <String, int>{};
  }

  // 家事ログを曜日と家事IDでグループ化
  for (final workLog in workLogs) {
    final weekday = workLog.completedAt.weekday % 7; // 0-6の値（0が日曜日）
    final houseWorkId = workLog.houseWorkId;

    weekdayMap[weekday]![houseWorkId] =
        (weekdayMap[weekday]![houseWorkId] ?? 0) + 1;
  }

  // WeekdayFrequencyのリストを作成
  final result = <WeekdayFrequency>[];
  for (var i = 0; i < 7; i++) {
    final houseWorkFrequencies = <HouseWorkFrequency>[];
    var totalCount = 0;

    // 各家事IDごとの頻度を取得
    for (final entry in weekdayMap[i]!.entries) {
      final houseWork = await houseWorkRepository.getByIdOnce(entry.key);

      if (houseWork != null) {
        houseWorkFrequencies.add(
          HouseWorkFrequency(houseWork: houseWork, count: entry.value),
        );
        totalCount += entry.value;
      }
    }

    // 頻度の高い順にソート
    houseWorkFrequencies.sort((a, b) => b.count.compareTo(a.count));

    result.add(
      WeekdayFrequency(
        weekday: weekdayNames[i],
        houseWorkFrequencies: houseWorkFrequencies,
        totalCount: totalCount,
      ),
    );
  }

  final colors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.amber,
    Colors.indigo,
  ];

  // 凡例データの収集
  final allHouseWorks = <HouseWork>{};
  final houseWorkColorMap = <String, Color>{};

  // すべての家事を収集し、それぞれに色を割り当てる
  for (final day in result) {
    for (var i = 0; i < day.houseWorkFrequencies.length; i++) {
      final houseWork = day.houseWorkFrequencies[i].houseWork;
      allHouseWorks.add(houseWork);
      if (!houseWorkColorMap.containsKey(houseWork.id)) {
        houseWorkColorMap[houseWork.id] =
            colors[houseWorkColorMap.length % colors.length];
      }
    }
  }

  // 家事を集約してリスト化（凡例用）
  final legendItems = allHouseWorks.toList();

  // 表示・非表示の状態に基づいて、各曜日のデータをフィルタリング
  final filteredWeekdayData =
      result.map((day) {
        // 表示する家事だけをフィルタリング
        final visibleFrequencies =
            day.houseWorkFrequencies
                .where(
                  (freq) => houseWorkVisibilities[freq.houseWork.id] ?? true,
                )
                .toList();

        // 表示する家事の合計回数を計算
        final visibleTotalCount = visibleFrequencies.fold(
          0,
          (sum, freq) => sum + freq.count,
        );

        // 新しいWeekdayFrequencyオブジェクトを作成
        return WeekdayFrequency(
          weekday: day.weekday,
          houseWorkFrequencies: visibleFrequencies,
          totalCount: visibleTotalCount,
        );
      }).toList();

  return filteredWeekdayData;
}

@riverpod
Stream<List<HouseWork>> _houseWorksFilePrivate(Ref ref) {
  final houseWorkRepositoryAsync = ref.watch(houseWorkRepositoryProvider);

  return houseWorkRepositoryAsync.when(
    data: (repository) => repository.getAll(),
    error: (error, stack) => Stream.error(error),
    loading: Stream.empty,
  );
}

@riverpod
Stream<Map<String, Color>> _colorOfHouseWorksFilePrivate(Ref ref) {
  final houseWorksAsync = ref.watch(_houseWorksFilePrivateProvider);

  final colors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.amber,
    Colors.indigo,
  ];

  return houseWorksAsync.when(
    data: (houseWorks) {
      final colorsOfHouseWorks = <String, Color>{};

      for (final houseWork in houseWorks) {
        colorsOfHouseWorks[houseWork.id] =
            colors[colorsOfHouseWorks.length % colors.length];
      }

      return Stream.value(colorsOfHouseWorks);
    },
    error: (error, stack) => Stream.error(error),
    loading: Stream.empty,
  );
}
