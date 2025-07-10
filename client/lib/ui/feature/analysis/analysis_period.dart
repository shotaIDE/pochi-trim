import 'package:freezed_annotation/freezed_annotation.dart';

part 'analysis_period.freezed.dart';

enum AnalysisPeriodIdentifier {
  today,
  yesterday,
  currentWeek,
  currentMonth,
  pastWeek,
  pastTwoWeeks,
  pastMonth,
}

@freezed
sealed class AnalysisPeriod with _$AnalysisPeriod {
  factory AnalysisPeriod.today({required DateTime from, required DateTime to}) =
      AnalysisPeriodToday;
  factory AnalysisPeriod.yesterday({
    required DateTime from,
    required DateTime to,
  }) = AnalysisPeriodYesterday;
  factory AnalysisPeriod.currentWeek({
    required DateTime from,
    required DateTime to,
  }) = AnalysisPeriodCurrentWeek;
  factory AnalysisPeriod.pastWeek({
    required DateTime from,
    required DateTime to,
  }) = AnalysisPeriodPastWeek;
  factory AnalysisPeriod.pastTwoWeeks({
    required DateTime from,
    required DateTime to,
  }) = AnalysisPeriodPastTwoWeeks;
  factory AnalysisPeriod.currentMonth({
    required DateTime from,
    required DateTime to,
  }) = AnalysisPeriodCurrentMonth;
  factory AnalysisPeriod.pastMonth({
    required DateTime from,
    required DateTime to,
  }) = AnalysisPeriodPastMonth;
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

extension AnalysisPeriodYesterdayGenerator on AnalysisPeriodYesterday {
  static AnalysisPeriod fromCurrentDate(DateTime current) {
    final startOfYesterday = DateTime(
      current.year,
      current.month,
      current.day,
    ).subtract(const Duration(days: 1));
    final endOfYesterday = DateTime(
      current.year,
      current.month,
      current.day,
    ).subtract(const Duration(microseconds: 1));

    return AnalysisPeriod.yesterday(from: startOfYesterday, to: endOfYesterday);
  }
}

extension AnalysisPeriodPastWeekGenerator on AnalysisPeriodPastWeek {
  static AnalysisPeriod fromCurrentDate(DateTime current) {
    final endOfToday = DateTime(
      current.year,
      current.month,
      current.day,
    ).add(const Duration(days: 1)).subtract(const Duration(microseconds: 1));
    final startOfPastWeek = DateTime(
      current.year,
      current.month,
      current.day,
    ).subtract(const Duration(days: 6));

    return AnalysisPeriod.pastWeek(from: startOfPastWeek, to: endOfToday);
  }
}

extension AnalysisPeriodPastTwoWeeksGenerator on AnalysisPeriodPastTwoWeeks {
  static AnalysisPeriod fromCurrentDate(DateTime current) {
    final endOfToday = DateTime(
      current.year,
      current.month,
      current.day,
    ).add(const Duration(days: 1)).subtract(const Duration(microseconds: 1));
    final startOfPastTwoWeeks = DateTime(
      current.year,
      current.month,
      current.day,
    ).subtract(const Duration(days: 13));

    return AnalysisPeriod.pastTwoWeeks(
      from: startOfPastTwoWeeks,
      to: endOfToday,
    );
  }
}

extension AnalysisPeriodCurrentMonthGenerator on AnalysisPeriodCurrentMonth {
  static AnalysisPeriod fromCurrentDate(DateTime current) {
    final startOfCurrentMonth = DateTime(current.year, current.month);
    final startOfNextMonth = (current.month < 12)
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

extension AnalysisPeriodPastMonthGenerator on AnalysisPeriodPastMonth {
  static AnalysisPeriod fromCurrentDate(DateTime current) {
    final endOfToday = DateTime(
      current.year,
      current.month,
      current.day,
    ).add(const Duration(days: 1)).subtract(const Duration(microseconds: 1));

    // 過去30日間を計算
    final startOfPastMonth = DateTime(
      current.year,
      current.month,
      current.day,
    ).subtract(const Duration(days: 29));

    return AnalysisPeriod.pastMonth(from: startOfPastMonth, to: endOfToday);
  }
}
