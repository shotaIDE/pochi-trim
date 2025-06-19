import 'package:freezed_annotation/freezed_annotation.dart';

part 'debounce_work_log_exception.freezed.dart';

/// デバウンス判定により家事ログの登録が拒否された場合にスローされる例外
@freezed
class DebounceWorkLogException
    with _$DebounceWorkLogException
    implements Exception {
  const factory DebounceWorkLogException() = _DebounceWorkLogException;
}
