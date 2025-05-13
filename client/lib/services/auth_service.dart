import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore: unused_import
import 'package:google_sign_in/google_sign_in.dart';
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

class AuthService {
  final _logger = Logger('AuthService');

  Future<SignInResult> signInWithGoogle() async {
    final authCredential = await _loginGoogle();

    final firebase_auth.UserCredential userCredential;
    try {
      userCredential = await firebase_auth.FirebaseAuth.instance
          .signInWithCredential(authCredential);
    } on firebase_auth.FirebaseAuthException catch (error) {
      if (error.code == 'credential-already-in-use') {
        _logger.warning('This Google account is already in use.');

        throw const SignInException.alreadyInUse();
      }

      throw const SignInException.uncategorized();
    }

    final user = userCredential.user!;

    _logger.info('Signed in with Google.');

    return SignInResult.success(
      userId: user.uid,
      isNewUser: userCredential.additionalUserInfo?.isNewUser ?? false,
    );
  }

  Future<void> linkWithGoogle() async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser!;

    final authCredential = await _loginGoogle();

    try {
      await user.linkWithCredential(authCredential);
    } on firebase_auth.FirebaseAuthException catch (error) {
      if (error.code == 'credential-already-in-use') {
        _logger.warning('This Google account is already in use.');

        throw const SignInException.alreadyInUse();
      }

      throw const SignInException.uncategorized();
    }

    _logger.info('Linked with Google account.');
  }

  Future<String> signInAnonymously() async {
    final userCredential =
        await firebase_auth.FirebaseAuth.instance.signInAnonymously();

    final user = userCredential.user!;

    _logger.info('Signed in anonymously. user ID = ${user.uid}');

    return user.uid;
  }

  Future<void> signOut() async {
    await firebase_auth.FirebaseAuth.instance.signOut();
  }

  /// 現在のユーザー情報をチェックし、ログインしている場合はUIDをログ出力します
  void checkCurrentUser() {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    _logger.info('既存ユーザーがログイン中です。UID: ${user.uid}');
  }

  Future<firebase_auth.AuthCredential> _loginGoogle() async {
    final executor = GoogleSignIn();
    final account = await executor.signIn();
    if (account == null) {
      throw const SignInException.cancelled();
    }

    final authentication = await account.authentication;
    final idToken = authentication.idToken;
    final accessToken = authentication.accessToken;
    if (idToken == null || accessToken == null) {
      throw const SignInException.uncategorized();
    }

    _logger.info(
      'Signed in Google account: '
      'user ID = ${account.id}, '
      'display name = ${account.displayName}, '
      'email = ${account.email}, '
      'photo URL = ${account.photoUrl}',
    );

    return firebase_auth.GoogleAuthProvider.credential(
      idToken: idToken,
      accessToken: accessToken,
    );
  }
}
