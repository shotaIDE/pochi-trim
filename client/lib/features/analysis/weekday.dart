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
}
