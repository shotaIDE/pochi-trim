import 'package:freezed_annotation/freezed_annotation.dart';

part 'sign_in_apple_exception.freezed.dart';

@freezed
sealed class SignInAppleException
    with _$SignInAppleException
    implements Exception {
  const factory SignInAppleException.cancelled() =
      SignInAppleExceptionCancelled;

  const factory SignInAppleException.uncategorized() =
      SignInAppleExceptionUncategorized;
}
