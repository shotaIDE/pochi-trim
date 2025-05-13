import 'package:firebase_auth/firebase_auth.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';

@freezed
sealed class UserProfile with _$UserProfile {
  const factory UserProfile.withGoogleAccount({
    required String id,
    required String? displayName,
    required String? email,
    required String? photoUrl,
  }) = UserProfileWithGoogleAccount;

  const factory UserProfile.withAppleAccount({
    required String id,
    required String? displayName,
    required String? email,
  }) = UserProfileWithAppleAccount;

  const factory UserProfile.anonymous({required String id}) =
      UserProfileAnonymous;

  const UserProfile._();

  factory UserProfile.fromFirebaseAuthUser(User user) {
    if (user.isAnonymous) {
      return UserProfile.anonymous(id: user.uid);
    }

    final providerData = user.providerData.firstOrNull;
    if (providerData == null) {
      return UserProfile.anonymous(id: user.uid);
    }

    switch (providerData.providerId) {
      case 'google.com':
        return UserProfile.withGoogleAccount(
          id: user.uid,
          displayName: user.displayName,
          email: user.email,
          photoUrl: user.photoURL,
        );
      case 'apple.com':
        return UserProfile.withAppleAccount(
          id: user.uid,
          displayName: user.displayName,
          email: user.email,
        );
      default:
        throw UnsupportedProviderError(providerData.providerId);
    }
  }
}

class UnsupportedProviderError extends Error {
  UnsupportedProviderError(this.providerId);

  final String providerId;

  @override
  String toString() {
    return 'Unsupported provider: $providerId';
  }
}
