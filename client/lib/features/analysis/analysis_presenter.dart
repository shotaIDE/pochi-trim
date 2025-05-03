import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

// TODO(ide): keepAlive = false にできないか？
@Riverpod(keepAlive: true)
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
  final workLogRepository = ref.watch(workLogRepositoryProvider);

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
Future<WeekdayStatistics> weekdayStatisticsDisplay(
  Ref ref, {
  required int period,
}) async {
  final workLogs = await ref.watch(filteredWorkLogsProvider(period).future);
  final houseWorkVisibilities = ref.watch(houseWorkVisibilitiesProvider);
  final houseWorks = await ref.watch(_houseWorksFilePrivateProvider.future);
  final colorOfHouseWorks = await ref.watch(
    _colorOfHouseWorksFilePrivateProvider.future,
  );

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
