import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/features/analysis/analysis_period.dart';
import 'package:house_worker/features/analysis/analysis_screen.dart';
import 'package:house_worker/features/analysis/weekday.dart';
import 'package:house_worker/features/analysis/weekday_frequency.dart';
import 'package:house_worker/features/analysis/weekday_statistics.dart';
import 'package:house_worker/models/house_work.dart';
import 'package:house_worker/models/work_log.dart';
import 'package:house_worker/repositories/house_work_repository.dart';
import 'package:house_worker/repositories/work_log_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'analysis_presenter.g.dart';

@riverpod
class CurrentAnalysisPeriod extends _$CurrentAnalysisPeriod {
  @override
  AnalysisPeriod build() {
    return AnalysisPeriodCurrentWeekGenerator.fromCurrentDate(DateTime.now());
  }

  // ignore: use_setters_to_change_properties
  void setPeriod(AnalysisPeriod period) {
    state = period;
  }
}

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
Future<List<WorkLog>> workLogsFilteredByPeriod(Ref ref) async {
  return ref.watch(_workLogsFilteredByPeriodFilePrivateProvider.future);
}

@riverpod
Future<WeekdayStatistics> weekdayStatisticsDisplay(Ref ref) async {
  // 順番に `.future` 値を `await` により取得すると、
  // 非同期処理の隙間で各 Provider のリスナーが存在しない状態が生まれ、
  // Riverpod によりステートが破棄され、状態がリセットされてしまう。
  // これを防ぐために、全ての Provider を `watch` してから、後で一気に `await` する。
  final workLogsFuture = ref.watch(
    _workLogsFilteredByPeriodFilePrivateProvider.future,
  );
  final houseWorksFuture = ref.watch(_houseWorksFilePrivateProvider.future);
  final houseWorkVisibilities = ref.watch(houseWorkVisibilitiesProvider);
  final colorOfHouseWorksFuture = ref.watch(
    _colorOfHouseWorksFilePrivateProvider.future,
  );

  final workLogs = await workLogsFuture;
  final houseWorks = await houseWorksFuture;
  final colorOfHouseWorks = await colorOfHouseWorksFuture;

  final workLogCountsStatistics =
      Weekday.values.map((weekday) {
        final targetWorkLogs =
            workLogs
                .where(
                  (workLog) => workLog.completedAt.weekday == weekday.value,
                )
                .toList();

        final workLogCountsForHouseWork =
            houseWorks
                .map((houseWork) {
                  final workLogsOfTargetHouseWork = targetWorkLogs.where((
                    workLog,
                  ) {
                    return workLog.houseWorkId == houseWork.id;
                  });

                  return HouseWorkFrequency(
                    houseWork: houseWork,
                    count: workLogsOfTargetHouseWork.length,
                    color: colorOfHouseWorks[houseWork.id] ?? Colors.grey,
                  );
                })
                // 家事ログが1回以上記録されたものだけを表示する
                .where((houseWorkFrequency) => houseWorkFrequency.count >= 1)
                .toList();

        final sortedWorkLogCountsForHouseWork =
            workLogCountsForHouseWork
                .sortedBy((workLogCount) => workLogCount.count)
                .reversed
                .toList();

        final totalCount = targetWorkLogs.length;

        return WeekdayFrequency(
          weekday: weekday,
          houseWorkFrequencies: sortedWorkLogCountsForHouseWork,
          totalCount: totalCount,
        );
      }).toList();

  final houseWorksSortedByStatistics =
      workLogCountsStatistics
          .expand((weekdayFrequency) => weekdayFrequency.houseWorkFrequencies)
          .map((houseWorkFrequency) => houseWorkFrequency.houseWork)
          // 重複を排除
          .toSet()
          .toList();
  final houseWorkLegends =
      houseWorksSortedByStatistics.map((houseWork) {
        final color = colorOfHouseWorks[houseWork.id] ?? Colors.grey;
        final isVisible = houseWorkVisibilities[houseWork.id] ?? true;

        return HouseWorkLegends(
          houseWork: houseWork,
          color: color,
          isVisible: isVisible,
        );
      }).toList();

  // 表示・非表示の状態に基づいて、各曜日のデータをフィルタリング
  final filteredWeekdayData =
      workLogCountsStatistics.map((day) {
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

        return WeekdayFrequency(
          weekday: day.weekday,
          houseWorkFrequencies: visibleFrequencies,
          totalCount: visibleTotalCount,
        );
      }).toList();

  return WeekdayStatistics(
    weekdayFrequencies: filteredWeekdayData,
    houseWorkLegends: houseWorkLegends,
  );
}

/// 時間帯ごとの家事実行頻度を取得するプロバイダー（期間フィルタリング付き）
@riverpod
Future<List<TimeSlotFrequency>> filteredTimeSlotFrequency(Ref ref) async {
  // 非同期処理の状態リセットを防ぐために、全てのプロバイダーを先に `watch` してから後で `await` する
  final workLogsFuture = ref.watch(workLogsFilteredByPeriodProvider.future);
  final houseWorkRepository = ref.watch(houseWorkRepositoryProvider);

  final workLogs = await workLogsFuture;

  // 時間帯の定義（3時間ごと）
  final timeSlots = [
    '0-3時',
    '3-6時',
    '6-9時',
    '9-12時',
    '12-15時',
    '15-18時',
    '18-21時',
    '21-24時',
  ];

  // 時間帯ごと、家事IDごとにグループ化して頻度をカウント
  final timeSlotMap = Map.fromEntries(
    List.generate(8, (i) => MapEntry(i, <String, int>{})),
  );

  // 家事ログを時間帯と家事IDでグループ化
  for (final workLog in workLogs) {
    final hour = workLog.completedAt.hour;
    final timeSlotIndex = hour ~/ 3; // 0-7のインデックス（3時間ごとの区分）
    final houseWorkId = workLog.houseWorkId;

    timeSlotMap[timeSlotIndex]![houseWorkId] =
        (timeSlotMap[timeSlotIndex]![houseWorkId] ?? 0) + 1;
  }

  // 各時間帯ごとにTimeSlotFrequencyを作成
  final result = await Future.wait(
    List.generate(8, (i) async {
      // 各家事IDごとの頻度を取得
      final houseWorkFrequenciesFutures = timeSlotMap[i]!.entries.map((
        entry,
      ) async {
        final houseWork = await houseWorkRepository.getByIdOnce(entry.key);
        if (houseWork == null) return null;

        return HouseWorkFrequency(houseWork: houseWork, count: entry.value);
      });

      // 非同期処理の結果を待機
      final houseWorkFrequenciesWithNull = await Future.wait(
        houseWorkFrequenciesFutures,
      );

      // nullでない結果だけをフィルタリング
      final houseWorkFrequencies =
          houseWorkFrequenciesWithNull.whereType<HouseWorkFrequency>().toList();

      // 頻度の高い順にソート
      houseWorkFrequencies.sortBy((freq) => -freq.count);

      // 合計回数を計算
      final totalCount = houseWorkFrequencies.fold(
        0,
        (sum, freq) => sum + freq.count,
      );

      return TimeSlotFrequency(
        timeSlot: timeSlots[i],
        houseWorkFrequencies: houseWorkFrequencies,
        totalCount: totalCount,
      );
    }),
  );

  return result;
}

@riverpod
Stream<List<HouseWork>> _houseWorksFilePrivate(Ref ref) {
  final houseWorkRepository = ref.watch(houseWorkRepositoryProvider);

  return houseWorkRepository.getAll();
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

@riverpod
Future<List<WorkLog>> _workLogsFilteredByPeriodFilePrivate(Ref ref) async {
  final currentAnalysisPeriod = ref.watch(currentAnalysisPeriodProvider);
  final workLogRepository = ref.watch(workLogRepositoryProvider);

  final allWorkLogs = await workLogRepository.getAllOnce();

  return allWorkLogs
    ..where(
      (log) =>
          log.completedAt.isAfter(currentAnalysisPeriod.from) &&
          log.completedAt.isBefore(currentAnalysisPeriod.to),
    ).toList();
}
