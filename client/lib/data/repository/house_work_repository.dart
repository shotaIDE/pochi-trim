import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pochi_trim/data/model/house_work.dart';
import 'package:pochi_trim/data/repository/dao/add_house_work_args.dart';
import 'package:pochi_trim/data/repository/house_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'house_work_repository.g.dart';

@riverpod
HouseWorkRepository houseWorkRepository(Ref ref) {
  final currentHouseId = ref.watch(unwrappedCurrentHouseIdProvider);

  return HouseWorkRepository(houseId: currentHouseId);
}

/// 家事リポジトリ
/// 家事の基本情報を管理するためのリポジトリ
class HouseWorkRepository {
  HouseWorkRepository({required String houseId}) : _houseId = houseId;

  final String _houseId;

  Future<String> add(AddHouseWorkArgs args) async {
    final houseWorksCollection = _getAllCollectionReference();

    final docRef = await houseWorksCollection.add(args.toFirestore());
    return docRef.id;
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
