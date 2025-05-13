import 'package:freezed_annotation/freezed_annotation.dart';

part 'sign_in_result.freezed.dart';

@freezed
sealed class SignInResult with _$SignInResult {
  const factory SignInResult.success({
    required String userId,
    required bool isNewUser,
  }) = SignInSuccess;

  const factory SignInResult.cancelled() = SignInCancelled;
}

@freezed
sealed class SignInException with _$SignInException implements Exception {
  const factory SignInException.cancelled() = SignInExceptionCancelled;

  const factory SignInException.alreadyInUse() = SignInExceptionAlreadyInUse;

  const factory SignInException.uncategorized() = SignInExceptionUncategorized;
}
