import 'package:freezed_annotation/freezed_annotation.dart';

part 'analysis_period.freezed.dart';

@freezed
sealed class AnalysisPeriod with _$AnalysisPeriod {
  AnalysisPeriod._({required this.from, required this.to});

  factory AnalysisPeriod.today({required DateTime from, required DateTime to}) =
      AnalysisPeriodToday;
  factory AnalysisPeriod.currentWeek({
    required DateTime from,
    required DateTime to,
  }) = AnalysisPeriodCurrentWeek;
  factory AnalysisPeriod.currentMonth({
    required DateTime from,
    required DateTime to,
  }) = AnalysisPeriodCurrentMonth;

  @override
  final DateTime from;
  @override
  final DateTime to;
}

extension AnalysisPeriodTodayGenerator on AnalysisPeriodToday {
  static AnalysisPeriod fromCurrentDate(DateTime current) {
    final startOfToday = DateTime(current.year, current.month, current.day);
    final endOfToday = startOfToday
        .add(const Duration(days: 1))
        .subtract(const Duration(microseconds: 1));

    return AnalysisPeriod.today(from: startOfToday, to: endOfToday);
  }
}

extension AnalysisPeriodCurrentWeekGenerator on AnalysisPeriodCurrentWeek {
  static AnalysisPeriod fromCurrentDate(DateTime current) {
    final currentWeekday = current.weekday;
    final startOfCurrentWeek = DateTime(
      current.year,
      current.month,
      current.day,
    ).subtract(Duration(days: currentWeekday - 1));
    final endOfCurrentWeek = startOfCurrentWeek
        .add(const Duration(days: 7))
        .subtract(const Duration(microseconds: 1));

    return AnalysisPeriod.currentWeek(
      from: startOfCurrentWeek,
      to: endOfCurrentWeek,
    );
  }
}

extension AnalysisPeriodCurrentMonthGenerator on AnalysisPeriodCurrentMonth {
  static AnalysisPeriod fromCurrentDate(DateTime current) {
    final startOfCurrentMonth = DateTime(current.year, current.month);
    final startOfNextMonth =
        (current.month < 12)
            ? DateTime(current.year, current.month + 1)
            : DateTime(current.year + 1);
    final endOfCurrentMonth = startOfNextMonth.subtract(
      const Duration(microseconds: 1),
    );

    return AnalysisPeriod.currentMonth(
      from: startOfCurrentMonth,
      to: endOfCurrentMonth,
    );
  }
}
