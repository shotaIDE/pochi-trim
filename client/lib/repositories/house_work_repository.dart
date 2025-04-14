import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/models/house_work.dart';
import 'package:logging/logging.dart';

final _logger = Logger('HouseWorkRepository');

final houseWorkRepositoryProvider = Provider<HouseWorkRepository>((ref) {
  return HouseWorkRepository();
});

/// 家事リポジトリ
/// 家事の基本情報を管理するためのリポジトリ
class HouseWorkRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ハウスIDを指定して家事コレクションの参照を取得
  CollectionReference _getHouseWorksCollection(String houseId) {
    return _firestore
        .collection('houses')
        .doc(houseId)
        .collection('houseWorks');
  }

  /// 家事を保存する
  Future<String> save(String houseId, HouseWork houseWork) async {
    final houseWorksCollection = _getHouseWorksCollection(houseId);

    if (houseWork.id.isEmpty) {
      // 新規家事の場合
      final docRef = await houseWorksCollection.add(houseWork.toFirestore());
      return docRef.id;
    } else {
      // 既存家事の更新
      await houseWorksCollection
          .doc(houseWork.id)
          .update(houseWork.toFirestore());
      return houseWork.id;
    }
  }

  /// 複数の家事を一括保存する
  Future<List<String>> saveAll(
    String houseId,
    List<HouseWork> houseWorks,
  ) async {
    final ids = <String>[];
    for (final houseWork in houseWorks) {
      final id = await save(houseId, houseWork);
      ids.add(id);
    }
    return ids;
  }

  /// IDを指定して家事を取得する
  Future<HouseWork?> getById(String houseId, String id) async {
    final doc = await _getHouseWorksCollection(houseId).doc(id).get();
    if (doc.exists) {
      return HouseWork.fromFirestore(doc);
    }
    return null;
  }

  Stream<List<HouseWork>> getAll({required String houseId}) {
    return _getHouseWorksCollection(houseId)
        .orderBy('createdBy', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(HouseWork.fromFirestore).toList());
  }

  Future<List<HouseWork>> getAllOnce(String houseId) async {
    final querySnapshot = await _getHouseWorksCollection(houseId).get();
    return querySnapshot.docs.map(HouseWork.fromFirestore).toList();
  }

  /// 家事を削除する
  Future<bool> delete(String houseId, String id) async {
    try {
      await _getHouseWorksCollection(houseId).doc(id).delete();
      return true;
    } on FirebaseException catch (e) {
      _logger.warning('家事削除エラー', e);
      return false;
    }
  }

  /// すべての家事を削除する
  Future<void> deleteAll(String houseId) async {
    final querySnapshot = await _getHouseWorksCollection(houseId).get();
    final batch = _firestore.batch();

    for (final doc in querySnapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  /// 共有されている家事を取得する
  Future<List<HouseWork>> getSharedHouseWorks(String houseId) async {
    final querySnapshot =
        await _getHouseWorksCollection(houseId)
            .where('isShared', isEqualTo: true)
            .orderBy('priority', descending: true)
            .get();

    return querySnapshot.docs.map(HouseWork.fromFirestore).toList();
  }

  /// 繰り返し設定がある家事を取得する
  Future<List<HouseWork>> getRecurringHouseWorks(String houseId) async {
    final querySnapshot =
        await _getHouseWorksCollection(houseId)
            .where('isRecurring', isEqualTo: true)
            .orderBy('priority', descending: true)
            .get();

    return querySnapshot.docs.map(HouseWork.fromFirestore).toList();
  }

  /// タイトルで家事を検索する
  Future<List<HouseWork>> getHouseWorksByTitle(
    String houseId,
    String title,
  ) async {
    final querySnapshot =
        await _getHouseWorksCollection(houseId)
            .where('title', isEqualTo: title)
            .orderBy('createdAt', descending: true)
            .get();

    return querySnapshot.docs.map(HouseWork.fromFirestore).toList();
  }

  /// 特定のユーザーが作成した家事を取得する
  Future<List<HouseWork>> getHouseWorksByUser(
    String houseId,
    String userId,
  ) async {
    final querySnapshot =
        await _getHouseWorksCollection(houseId)
            .where('createdBy', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .get();

    return querySnapshot.docs.map(HouseWork.fromFirestore).toList();
  }
}
