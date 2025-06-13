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

@freezed
sealed class DeleteAccountResult with _$DeleteAccountResult {
  const factory DeleteAccountResult.success() = DeleteAccountResultSuccess;

  const factory DeleteAccountResult.requiresRecentLogin() =
      DeleteAccountResultRequiresRecentLogin;

  const factory DeleteAccountResult.uncategorized() =
      DeleteAccountResultUncategorized;

  const factory DeleteAccountResult.generalError(String message) =
      DeleteAccountResultGeneralError;
}
