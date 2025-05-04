class MaxHouseWorkLimitExceededException implements Exception {
  final message = 'フリー版では最大10件までの家事しか登録できません。Pro版にアップグレードすると、無制限に家事を登録できます。';

  @override
  String toString() => message;
}
