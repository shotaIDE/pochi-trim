/// 家事ログの更新に失敗した際にスローされる例外
class UpdateWorkLogException implements Exception {
  const UpdateWorkLogException();

  @override
  String toString() => 'UpdateWorkLogException: Failed to update work log';
}
