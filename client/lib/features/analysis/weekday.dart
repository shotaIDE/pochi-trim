enum Weekday {
  monday(value: DateTime.monday),
  tuesday(value: DateTime.tuesday),
  wednesday(value: DateTime.wednesday),
  thursday(value: DateTime.thursday),
  friday(value: DateTime.friday),
  saturday(value: DateTime.saturday),
  sunday(value: DateTime.sunday);

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
