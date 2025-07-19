import 'package:freezed_annotation/freezed_annotation.dart';

part 'update_work_log_exception.freezed.dart';

/// 家事ログの更新に失敗した際にスローされる例外
@freezed
sealed class UpdateWorkLogException
    with _$UpdateWorkLogException
    implements Exception {
  const factory UpdateWorkLogException.futureDateTime() =
      UpdateWorkLogExceptionFutureDateTime;

  const factory UpdateWorkLogException.uncategorized() =
      UpdateWorkLogExceptionUncategorized;
}
