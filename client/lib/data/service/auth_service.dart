import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logging/logging.dart';
import 'package:pochi_trim/data/model/delete_account_exception.dart';
import 'package:pochi_trim/data/model/sign_in_result.dart';
import 'package:pochi_trim/data/model/user_profile.dart';
import 'package:pochi_trim/data/service/error_report_service.dart';
import 'package:pochi_trim/data/service/sign_in_google_exception.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_service.g.dart';

@riverpod
AuthService authService(Ref ref) {
  return AuthService(errorReportService: ref.watch(errorReportServiceProvider));
}

@riverpod
Stream<bool> isSignedIn(Ref ref) {
  return firebase_auth.FirebaseAuth.instance.authStateChanges().map((user) {
    if (user == null) {
      return false;
    }

    return true;
  });
}

@riverpod
Stream<UserProfile?> currentUserProfile(Ref ref) {
  return firebase_auth.FirebaseAuth.instance.userChanges().map((user) {
    if (user == null) {
      return null;
    }

    return UserProfile.fromFirebaseAuthUser(user);
  });
}

class AuthService {
  AuthService({required ErrorReportService errorReportService})
    : _errorReportService = errorReportService;

  final ErrorReportService _errorReportService;
  final _logger = Logger('AuthService');

  Future<SignInResult> signInWithGoogle() async {
    final firebase_auth.AuthCredential authCredential;
    try {
      authCredential = await _loginGoogle();
    } on SignInGoogleException catch (error) {
      switch (error) {
        case SignInGoogleExceptionCancelled():
          _logger.warning('Googleサインインがキャンセルされました。');

          throw const SignInWithGoogleException.cancelled();
        case SignInGoogleExceptionUncategorized():
          _logger.warning('Googleサインインに失敗しました。');

          unawaited(
            _errorReportService.recordError(
              error,
              StackTrace.current,
            ),
          );
          throw const SignInWithGoogleException.uncategorized();
      }
    }

    final firebase_auth.UserCredential userCredential;
    try {
      userCredential = await firebase_auth.FirebaseAuth.instance
          .signInWithCredential(authCredential);
    } on firebase_auth.FirebaseAuthException catch (e, stack) {
      unawaited(_errorReportService.recordError(e, stack));
      throw const SignInWithGoogleException.uncategorized();
    }

    final user = userCredential.user!;

    _logger.info('Googleでサインインしました。');

    return SignInResult(
      userId: user.uid,
      isNewUser: userCredential.additionalUserInfo?.isNewUser ?? false,
    );
  }

  Future<void> linkWithGoogle() async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser!;

    final firebase_auth.AuthCredential authCredential;
    try {
      authCredential = await _loginGoogle();
    } on SignInGoogleException catch (error) {
      switch (error) {
        case SignInGoogleExceptionCancelled():
          _logger.warning('Googleサインインがキャンセルされました。');

          throw const LinkWithGoogleException.cancelled();
        case SignInGoogleExceptionUncategorized():
          _logger.warning('Googleサインインに失敗しました。');

          unawaited(
            _errorReportService.recordError(
              error,
              StackTrace.current,
            ),
          );
          throw const LinkWithGoogleException.uncategorized();
      }
    }

    try {
      await user.linkWithCredential(authCredential);
    } on firebase_auth.FirebaseAuthException catch (error) {
      if (error.code == 'credential-already-in-use') {
        _logger.warning('このGoogleアカウントは既に使用されています。');

        throw const LinkWithGoogleException.alreadyInUse();
      }

      unawaited(_errorReportService.recordError(error, StackTrace.current));
      throw const LinkWithGoogleException.uncategorized();
    }

    _logger.info('Googleアカウントと連携しました。');
  }

  Future<SignInResult> signInWithApple() async {
    final appleAuthProvider = _getAppleAuthProvider();

    final firebase_auth.UserCredential userCredential;
    try {
      userCredential = await firebase_auth.FirebaseAuth.instance
          .signInWithProvider(appleAuthProvider);
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'canceled') {
        throw const SignInWithAppleException.cancelled();
      }

      unawaited(_errorReportService.recordError(e, StackTrace.current));
      throw const SignInWithAppleException.uncategorized();
    }

    final user = userCredential.user;
    if (user == null) {
      const exception = SignInWithAppleException.uncategorized();
      unawaited(
        _errorReportService.recordError(
          exception,
          StackTrace.current,
        ),
      );
      throw exception;
    }

    return SignInResult(
      userId: user.uid,
      isNewUser: userCredential.additionalUserInfo?.isNewUser ?? false,
    );
  }

  Future<void> linkWithApple() async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser!;

    final appleAuthProvider = _getAppleAuthProvider();

    try {
      await user.linkWithProvider(appleAuthProvider);
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'canceled') {
        throw const LinkWithAppleException.cancelled();
      }

      if (e.code == 'credential-already-in-use') {
        throw const LinkWithAppleException.alreadyInUse();
      }

      unawaited(_errorReportService.recordError(e, StackTrace.current));
      throw const LinkWithAppleException.uncategorized();
    }
  }

  Future<String> signInAnonymously() async {
    final userCredential = await firebase_auth.FirebaseAuth.instance
        .signInAnonymously();

    final user = userCredential.user!;

    _logger.info('匿名でサインインしました。ユーザーID = ${user.uid}');

    return user.uid;
  }

  Future<void> signOut() async {
    await firebase_auth.FirebaseAuth.instance.signOut();
  }

  Future<void> deleteAccount() async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser!;

    try {
      await user.delete();
    } on firebase_auth.FirebaseAuthException catch (e, stack) {
      if (e.code == 'requires-recent-login') {
        _logger.warning('アカウント削除には最新のログインが必要です。');

        throw const DeleteAccountException.requiresRecentLogin();
      }

      _logger.severe('アカウント削除に失敗しました: ${e.message}');
      // Crashlyticsにエラーレポートを送信（元々キャッチしたFirebaseAuthExceptionを送信）
      await _errorReportService.recordError(e, stack);

      throw const DeleteAccountException.uncategorized();
    }

    _logger.info('ユーザーアカウントを正常に削除しました。');
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
    final executor = GoogleSignIn(
      scopes: [
        'https://www.googleapis.com/auth/userinfo.email',
        'https://www.googleapis.com/auth/userinfo.profile',
      ],
    );
    final account = await executor.signIn();
    if (account == null) {
      throw const SignInGoogleException.cancelled();
    }

    final authentication = await account.authentication;
    final idToken = authentication.idToken;
    final accessToken = authentication.accessToken;
    if (idToken == null || accessToken == null) {
      throw const SignInGoogleException.uncategorized();
    }

    _logger.info(
      'Googleアカウントでサインインしました: '
      'ユーザーID = ${account.id}, '
      '表示名 = ${account.displayName}, '
      'メール = ${account.email}, '
      '写真URL = ${account.photoUrl}',
    );

    return firebase_auth.GoogleAuthProvider.credential(
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  firebase_auth.AppleAuthProvider _getAppleAuthProvider() {
    return firebase_auth.AppleAuthProvider()
      ..addScope('email')
      ..addScope('name');
  }
}
