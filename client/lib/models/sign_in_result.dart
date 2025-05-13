import 'package:freezed_annotation/freezed_annotation.dart';

part 'sign_in_result.freezed.dart';

@freezed
sealed class SignInResult with _$SignInResult {
  const factory SignInResult({
    required String userId,
    required bool isNewUser,
  }) = _SignInResult;
}

@freezed
sealed class SignInWithGoogleException
    with _$SignInWithGoogleException
    implements Exception {
  const factory SignInWithGoogleException.cancelled() =
      SignInWithGoogleExceptionCancelled;

  const factory SignInWithGoogleException.uncategorized() =
      SignInWithGoogleExceptionUncategorized;
}

@freezed
sealed class LinkWithGoogleException
    with _$LinkWithGoogleException
    implements Exception {
  const factory LinkWithGoogleException.cancelled() =
      LinkWithGoogleExceptionCancelled;

  const factory LinkWithGoogleException.alreadyInUse() =
      LinkWithGoogleExceptionAlreadyInUse;

  const factory LinkWithGoogleException.uncategorized() =
      LinkWithGoogleExceptionUncategorized;
}
