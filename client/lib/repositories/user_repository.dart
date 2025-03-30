import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/models/user.dart' as app_user;
import 'package:logging/logging.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

class UserRepository {
  final _logger = Logger('UserRepository');
  final CollectionReference _usersCollection = FirebaseFirestore.instance
      .collection('users');

  // ユーザーを作成または更新
  Future<String> save(app_user.User user) async {
    if (user.id.isEmpty) {
      // 新規ユーザーの場合
      final docRef = await _usersCollection.add(user.toFirestore());
      return docRef.id;
    } else {
      // 既存ユーザーの更新
      await _usersCollection.doc(user.id).update(user.toFirestore());
      return user.id;
    }
  }

  // 全ユーザーを取得
  Future<List<app_user.User>> getAll() async {
    final querySnapshot = await _usersCollection.get();
    return querySnapshot.docs.map(app_user.User.fromFirestore).toList();
  }

  // IDでユーザーを取得
  Future<app_user.User?> getById(String id) async {
    final doc = await _usersCollection.doc(id).get();
    if (doc.exists) {
      return app_user.User.fromFirestore(doc);
    }
    return null;
  }

  // ユーザーを削除
  Future<bool> delete(String id) async {
    try {
      await _usersCollection.doc(id).delete();
      return true;
    } on FirebaseException catch (e) {
      _logger.warning('ユーザー削除エラー: $e');
      return false;
    }
  }

  // Firebase UIDでユーザーを取得
  Future<app_user.User?> getUserByUid(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      if (doc.exists) {
        return app_user.User.fromFirestore(doc);
      }
      return null;
    } on FirebaseException catch (e) {
      _logger.warning('UIDによるユーザー取得エラー: $e');
      return null;
    }
  }

  // ユーザーを作成
  Future<String> createUser(app_user.User user) {
    return save(user);
  }

  // ユーザーを更新
  Future<void> updateUser(app_user.User user) {
    return save(user);
  }

  // 全ユーザーを取得
  Future<List<app_user.User>> getAllUsers() {
    return getAll();
  }
}
