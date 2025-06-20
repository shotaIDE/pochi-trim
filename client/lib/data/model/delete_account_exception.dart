import 'package:freezed_annotation/freezed_annotation.dart';

part 'delete_account_exception.freezed.dart';

@freezed
sealed class DeleteAccountException
    with _$DeleteAccountException
    implements Exception {
  const factory DeleteAccountException.requiresRecentLogin() =
      DeleteAccountExceptionRequiresRecentLogin;

  const factory DeleteAccountException.uncategorized() =
      DeleteAccountExceptionUncategorized;
}
