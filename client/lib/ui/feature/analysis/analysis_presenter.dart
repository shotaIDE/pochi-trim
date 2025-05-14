import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/models/house_work.dart';
import 'package:house_worker/models/work_log.dart';
import 'package:house_worker/repositories/house_work_repository.dart';
import 'package:house_worker/repositories/work_log_repository.dart';
import 'package:house_worker/ui/feature/analysis/analysis_period.dart';
import 'package:house_worker/ui/feature/analysis/analysis_screen.dart';
import 'package:house_worker/ui/feature/analysis/statistics.dart';
import 'package:house_worker/ui/feature/analysis/weekday.dart';
import 'package:house_worker/ui/feature/analysis/weekday_frequency.dart';
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
  String? _focusingHouseWorkId;
  Map<String, bool> _stateBeforeFocus = {};

  @override
  Map<String, bool> build() {
    return {};
  }

  void toggle({required String houseWorkId}) {
    final newState = Map<String, bool>.from(state);

    newState[houseWorkId] = !(state[houseWorkId] ?? true);

    state = newState;
  }

  /// 特定の凡例にフォーカスを当てるか、または、フォーカスを解除する
  ///
  /// フォーカスを当てると、他の凡例は非表示になる。
  Future<void> focusOrUnfocus({required String houseWorkId}) async {
    if (_focusingHouseWorkId == houseWorkId) {
      // すでにフォーカスしている場合は、フォーカスを解除する
      final newState = Map<String, bool>.from(_stateBeforeFocus);

      _focusingHouseWorkId = null;
      _stateBeforeFocus = {};

      state = newState;

      return;
    }

    final houseWorks = await ref.read(_houseWorksFilePrivateProvider.future);

    final newStateMapEntries = houseWorks.map((houseWork) {
      if (houseWork.id == houseWorkId) {
        return MapEntry(houseWork.id, true);
      }

      return MapEntry(houseWork.id, false);
    });
    final newState = Map<String, bool>.fromEntries(newStateMapEntries);

    if (_focusingHouseWorkId == null) {
      // 元々フォーカスがなかった場合にのみ、直前の状態を復元できるように保存しておく
      // 元々フォーカスがあった場合は、フォーカス状態より前の状態に復元したいので、ここでは状態を保存しない
      _stateBeforeFocus = Map<String, bool>.from(state);
    }

    _focusingHouseWorkId = houseWorkId;

    state = newState;
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

@riverpod
Future<TimeSlotStatistics> currentTimeSlotStatistics(Ref ref) async {
  final workLogsFuture = ref.watch(workLogsFilteredByPeriodProvider.future);
  final houseWorksFuture = ref.watch(_houseWorksFilePrivateProvider.future);
  final houseWorkVisibilities = ref.watch(houseWorkVisibilitiesProvider);
  final colorOfHouseWorksFuture = ref.watch(
    _colorOfHouseWorksFilePrivateProvider.future,
  );

  final workLogs = await workLogsFuture;
  final houseWorks = await houseWorksFuture;
  final colorOfHouseWorks = await colorOfHouseWorksFuture;

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

  final workLogCountsStatistics = List.generate(8, (timeSlotIndex) {
    final targetWorkLogs =
        workLogs
            .where((workLog) => workLog.completedAt.hour ~/ 3 == timeSlotIndex)
            .toList();

    final workLogCountsForHouseWork =
        houseWorks
            .map((houseWork) {
              final workLogsOfTargetHouseWork = targetWorkLogs.where((workLog) {
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

    return TimeSlotFrequency(
      timeSlot: timeSlots[timeSlotIndex],
      houseWorkFrequencies: sortedWorkLogCountsForHouseWork,
      totalCount: totalCount,
    );
  });

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

  // 表示・非表示の状態に基づいて、各時間帯のデータをフィルタリング
  final filteredTimeSlotData =
      workLogCountsStatistics.map((timeSlotFrequency) {
        final visibleFrequencies =
            timeSlotFrequency.houseWorkFrequencies
                .where(
                  (freq) => houseWorkVisibilities[freq.houseWork.id] ?? true,
                )
                .toList();

        // 表示する家事の合計回数を計算
        final visibleTotalCount = visibleFrequencies.fold(
          0,
          (sum, freq) => sum + freq.count,
        );

        return TimeSlotFrequency(
          timeSlot: timeSlotFrequency.timeSlot,
          houseWorkFrequencies: visibleFrequencies,
          totalCount: visibleTotalCount,
        );
      }).toList();

  return TimeSlotStatistics(
    timeSlotFrequencies: filteredTimeSlotData,
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

@riverpod
Future<List<WorkLog>> _workLogsFilteredByPeriodFilePrivate(Ref ref) async {
  final currentAnalysisPeriod = ref.watch(currentAnalysisPeriodProvider);
  final workLogRepository = ref.watch(workLogRepositoryProvider);

  final allWorkLogs = await workLogRepository.getAllOnce();

  return allWorkLogs
      .where(
        (log) =>
            log.completedAt.isAfter(currentAnalysisPeriod.from) &&
            log.completedAt.isBefore(currentAnalysisPeriod.to),
      )
      .toList();
}
