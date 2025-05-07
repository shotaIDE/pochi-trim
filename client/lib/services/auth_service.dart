import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/models/sign_in_result.dart';
import 'package:house_worker/models/user_profile.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_service.g.dart';

@riverpod
AuthService authService(Ref _) {
  return AuthService();
}

@riverpod
Stream<UserProfile?> currentUserProfile(Ref ref) {
  return firebase_auth.FirebaseAuth.instance.authStateChanges().map((user) {
    if (user == null) {
      return null;
    }

    return UserProfile.fromFirebaseAuthUser(user);
  });
}

final authStateProvider = StreamProvider<firebase_auth.User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

class AuthService {
  final _logger = Logger('AuthService');

  Stream<firebase_auth.User?> get authStateChanges =>
      firebase_auth.FirebaseAuth.instance.authStateChanges();

  Future<String> signInAnonymously() async {
    final firebase_auth.UserCredential userCredential;
    try {
      userCredential =
          await firebase_auth.FirebaseAuth.instance.signInAnonymously();
    } on firebase_auth.FirebaseAuthException catch (e) {
      _logger.warning('匿名ログインに失敗しました: $e');

      throw SignInException();
    }

    final user = userCredential.user;
    if (user == null) {
      throw SignInException();
    }

    _logger.info('ユーザーがログインしました。UID: ${user.uid}');

    return user.uid;
  }

  Future<void> signOut() async {
    await firebase_auth.FirebaseAuth.instance.signOut();
  }

  firebase_auth.User? get currentUser =>
      firebase_auth.FirebaseAuth.instance.currentUser;

  /// 現在のユーザー情報をチェックし、ログインしている場合はUIDをログ出力します
  void checkCurrentUser() {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    _logger.info('既存ユーザーがログイン中です。UID: ${user.uid}');
  }
}
