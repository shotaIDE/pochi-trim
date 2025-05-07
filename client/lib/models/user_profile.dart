import 'package:firebase_auth/firebase_auth.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';

@freezed
abstract class UserProfile with _$UserProfile {
  // TODO(ide): 匿名ユーザーかどうかを判定できるようにする
  const factory UserProfile({
    required String id,
    required String? displayName,
  }) = _UserProfile;

  const UserProfile._();

  factory UserProfile.fromFirebaseAuthUser(User user) {
    return UserProfile(id: user.uid, displayName: user.displayName ?? '');
  }
}
