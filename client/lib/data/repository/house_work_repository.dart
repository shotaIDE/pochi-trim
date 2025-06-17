import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:pochi_trim/data/model/app_session.dart';
import 'package:pochi_trim/data/model/delete_house_work_exception.dart';
import 'package:pochi_trim/data/model/house_work.dart';
import 'package:pochi_trim/data/model/no_house_id_error.dart';
import 'package:pochi_trim/data/repository/dao/add_house_work_args.dart';
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

  /// 家事とその関連する家事ログを削除する
  ///
  /// Throws:
  ///   - [DeleteHouseWorkException] - Firebaseエラー、ネットワークエラー、
  ///     権限エラーなどで削除に失敗した場合
  Future<void> delete(String houseWorkId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      
      await firestore.runTransaction((transaction) async {
        final houseWorkRef = _getAllCollectionReference().doc(houseWorkId);
        
        // 家事ドキュメントを削除
        transaction.delete(houseWorkRef);
        
        // 関連する家事ログを全て取得して削除
        final workLogsQuery = firestore
            .collection('houses')
            .doc(_houseId)
            .collection('workLogs')
            .where('houseWorkId', isEqualTo: houseWorkId);
            
        final workLogsSnapshot = await workLogsQuery.get();
        
        for (final workLogDoc in workLogsSnapshot.docs) {
          transaction.delete(workLogDoc.reference);
        }
      });
      
      _logger.info(
        'Successfully deleted house work $houseWorkId and its related '
        'work logs',
      );
    } on FirebaseException catch (e) {
      _logger.warning('家事削除エラー', e);
      
      throw DeleteHouseWorkException();
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
