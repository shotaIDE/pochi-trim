import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:pochi_trim/data/model/app_session.dart';
import 'package:pochi_trim/data/model/house_work.dart';
import 'package:pochi_trim/data/model/no_house_id_error.dart';
import 'package:pochi_trim/ui/root_presenter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'house_work_repository.g.dart';

final _logger = Logger('HouseWorkRepository');

@riverpod
HouseWorkRepository houseWorkRepository(Ref ref) {
  final appSession = ref.watch(unwrappedCurrentAppSessionProvider);

  switch (appSession) {
    case AppSessionSignedIn(currentHouseId: final currentHouseId):
      return HouseWorkRepository(houseId: currentHouseId);
    case AppSessionNotSignedIn():
      throw NoHouseIdError();
  }
}

/// 家事リポジトリ
/// 家事の基本情報を管理するためのリポジトリ
class HouseWorkRepository {
  HouseWorkRepository({required String houseId}) : _houseId = houseId;

  final String _houseId;

  /// 家事を保存する
  Future<String> save(HouseWork houseWork) async {
    final houseWorksCollection = _getAllCollectionReference();

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

  /// IDを指定して家事を取得する
  Future<HouseWork?> getByIdOnce(String houseWorkId) async {
    final doc = await _getAllCollectionReference().doc(houseWorkId).get();
    if (doc.exists) {
      return HouseWork.fromFirestore(doc);
    }
    return null;
  }

  /// すべての家事を作成日時の新しい順に取得する
  Stream<List<HouseWork>> getAll() {
    return _getAllQuerySortedByCreatedAtDescending().snapshots().map(
      (snapshot) => snapshot.docs.map(HouseWork.fromFirestore).toList(),
    );
  }

  Future<List<HouseWork>> getAllOnce() async {
    final querySnapshot = await _getAllQuerySortedByCreatedAtDescending().get();
    return querySnapshot.docs.map(HouseWork.fromFirestore).toList();
  }

  /// 家事を削除する
  Future<bool> delete(String id) async {
    try {
      await _getAllCollectionReference().doc(id).delete();
      return true;
    } on FirebaseException catch (e) {
      _logger.warning('家事削除エラー', e);
      return false;
    }
  }

  Query<Object?> _getAllQuerySortedByCreatedAtDescending() {
    return _getAllCollectionReference().orderBy('createdAt', descending: true);
  }

  CollectionReference _getAllCollectionReference() {
    return FirebaseFirestore.instance
        .collection('houses')
        .doc(_houseId)
        .collection('houseWorks');
  }
}
