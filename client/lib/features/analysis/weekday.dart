enum Weekday {
  monday(value: 0),
  tuesday(value: 1),
  wednesday(value: 2),
  thursday(value: 3),
  friday(value: 4),
  saturday(value: 5),
  sunday(value: 6);

  const Weekday({required this.value});

  /// 曜日の値
  ///
  /// `DateTime.weekday` の値に対応。
  final int value;

  String get displayName {
    switch (this) {
      case Weekday.monday:
        return '月曜日';
      case Weekday.tuesday:
        return '火曜日';
      case Weekday.wednesday:
        return '水曜日';
      case Weekday.thursday:
        return '木曜日';
      case Weekday.friday:
        return '金曜日';
      case Weekday.saturday:
        return '土曜日';
      case Weekday.sunday:
        return '日曜日';
    }
  }
}
