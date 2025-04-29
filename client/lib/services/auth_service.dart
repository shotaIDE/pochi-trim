import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/models/user.dart' as app_user;
import 'package:house_worker/repositories/user_repository.dart';
import 'package:logging/logging.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  final userRepository = ref.watch(userRepositoryProvider);
  return AuthService(firebase_auth.FirebaseAuth.instance, userRepository);
});

final authStateProvider = StreamProvider<firebase_auth.User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

class AuthService {
  AuthService(this._firebaseAuth, this._userRepository);
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final UserRepository _userRepository;
  final _logger = Logger('AuthService');

  Stream<firebase_auth.User?> get authStateChanges =>
      _firebaseAuth.authStateChanges();

  Future<void> signInAnonymously() async {
    try {
      final credential = await _firebaseAuth.signInAnonymously();
      final user = credential.user;

      if (user != null) {
        _logger.info('ユーザーがログインしました。UID: ${user.uid}');
        // ユーザーがデータベースに存在するか確認
        final existingUser = await _userRepository.getUserByUid(user.uid);

        if (existingUser == null) {
          // 新規ユーザーを作成
          final newUser = app_user.User(
            id: '', // 新規ユーザーの場合は空文字列を指定し、Firestoreが自動的にIDを生成
            uid: user.uid,
            name: 'ゲスト',
            email: user.email ?? '',
            householdIds: [],
            createdAt: DateTime.now(),
          );

          await _userRepository.createUser(newUser);
        }
      }
    } catch (e) {
      _logger.warning('匿名サインインに失敗しました: $e');
      // rethrow;
    }

    // Cloud Function APIを呼び出し
    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('generate_my_house');
      final result = await callable.call();
      debugPrint('Cloud Function Response: ${result.data}');
      _logger.info('generate_my_house APIの呼び出しに成功しました: ${result.data}');
    } catch (apiError) {
      debugPrint('Cloud Function Error: $apiError');
      _logger.warning('generate_my_house APIの呼び出しに失敗しました: $apiError');
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  firebase_auth.User? get currentUser => _firebaseAuth.currentUser;

  /// 現在のユーザー情報をチェックし、ログインしている場合はUIDをログ出力します
  void checkCurrentUser() {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      _logger.info('既存ユーザーがログイン中です。UID: ${user.uid}');
    }
  }
}
