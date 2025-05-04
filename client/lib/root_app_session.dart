import 'package:freezed_annotation/freezed_annotation.dart';

part 'root_app_session.freezed.dart';

@freezed
sealed class AppSession with _$AppSession {
  const AppSession._();

  factory AppSession.signedIn({
    required String userId,
    required String currentHouseId,
    required bool isPremium,
  }) = AppSessionSignedIn;
  factory AppSession.notSignedIn() = AppSessionNotSignedIn;
  factory AppSession.loading() = AppSessionLoading;
}
