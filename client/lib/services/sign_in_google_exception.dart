import 'package:freezed_annotation/freezed_annotation.dart';

part 'sign_in_google_exception.freezed.dart';

@freezed
sealed class SignInGoogleException
    with _$SignInGoogleException
    implements Exception {
  const factory SignInGoogleException.cancelled() =
      SignInGoogleExceptionCancelled;

  const factory SignInGoogleException.uncategorized() =
      SignInGoogleExceptionUncategorized;
}
