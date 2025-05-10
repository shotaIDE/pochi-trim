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

  Future<String> signInAnonymously() async {
    final firebase_auth.UserCredential userCredential;
    try {
      userCredential =
          await firebase_auth.FirebaseAuth.instance.signInAnonymously();
    } on firebase_auth.FirebaseAuthException catch (e) {
      _logger.warning('匿名ログインに失敗しました: $e');

      throw const SignInException.general();
    }

    final user = userCredential.user;
    if (user == null) {
      throw const SignInException.general();
    }

    _logger.info('ユーザーがログインしました。UID: ${user.uid}');

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

  Future<SignInResult> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn();

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return const SignInResult.cancelled();
      }

      final googleAuth = await googleUser.authentication;
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await firebase_auth.FirebaseAuth.instance
          .signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) {
        throw const SignInException.google();
      }

      _logger.info('ユーザーがGoogleアカウントでログインしました。UID: ${user.uid}');

      return SignInResult.success(
        userId: user.uid,
        isNewUser: userCredential.additionalUserInfo?.isNewUser ?? false,
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      _logger.warning('Googleログインに失敗しました: $e');
      throw const SignInException.google();
    }
  }

  Future<void> linkWithGoogle() async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw const SignInException.accountLink();
    }

    if (!user.isAnonymous) {
      throw const SignInException.accountLink();
    }

    try {
      final googleSignIn = GoogleSignIn();

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await user.linkWithCredential(credential);

      _logger.info('ユーザーが匿名アカウントをGoogleアカウントと連携しました。UID: ${user.uid}');
    } on firebase_auth.FirebaseAuthException catch (e) {
      _logger.warning('アカウント連携に失敗しました: $e');
      throw const SignInException.accountLink();
    }
  }
}
