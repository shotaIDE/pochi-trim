/// デバウンス判定により家事ログの登録が拒否された場合にスローされる例外
class DebounceWorkLogException implements Exception {
  const DebounceWorkLogException();
}
