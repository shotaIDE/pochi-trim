import 'package:firebase_auth/firebase_auth.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';

@freezed
sealed class UserProfile with _$UserProfile {
  const factory UserProfile.anonymous({required String id}) =
      UserProfileAnonymous;

  const factory UserProfile.withGoogleAccount({
    required String id,
    required String? displayName,
    required String? email,
    required String? photoUrl,
  }) = UserProfileWithGoogleAccount;

  const UserProfile._();

  factory UserProfile.fromFirebaseAuthUser(User user) {
    if (user.isAnonymous) {
      return UserProfile.anonymous(id: user.uid);
    }

    return UserProfile.withGoogleAccount(
      id: user.uid,
      displayName: user.displayName,
      email: user.email,
      photoUrl: user.photoURL,
    );
  }
}
