import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/models/sign_in_result.dart';
import 'package:house_worker/models/user.dart' as app_user;
import 'package:house_worker/repositories/user_repository.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_service.g.dart';

@riverpod
AuthService authService(Ref ref) {
  final userRepository = ref.watch(userRepositoryProvider);
  return AuthService(firebase_auth.FirebaseAuth.instance, userRepository);
}

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
    final firebase_auth.UserCredential userCredential;
    try {
      userCredential = await _firebaseAuth.signInAnonymously();
    } on firebase_auth.FirebaseAuthException catch (e) {
      _logger.warning('匿名ログインに失敗しました: $e');

      throw SignInException();
    }

    final user = userCredential.user;
    if (user == null) {
      throw SignInException();
    }

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
