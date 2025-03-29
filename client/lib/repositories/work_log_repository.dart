import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/models/work_log.dart';
import 'package:logging/logging.dart';

final _logger = Logger('WorkLogRepository');

final workLogRepositoryProvider = Provider<WorkLogRepository>((ref) {
  return WorkLogRepository();
});

class WorkLogRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ハウスIDを指定してワークログコレクションの参照を取得
  CollectionReference _getWorkLogsCollection(String houseId) {
    return _firestore.collection('houses').doc(houseId).collection('workLogs');
  }

  Future<String> save(String houseId, WorkLog workLog) async {
    final workLogsCollection = _getWorkLogsCollection(houseId);

    if (workLog.id.isEmpty) {
      // 新規ワークログの場合
      DocumentReference docRef = await workLogsCollection.add(
        workLog.toFirestore(),
      );
      return docRef.id;
    } else {
      // 既存ワークログの更新
      await workLogsCollection.doc(workLog.id).update(workLog.toFirestore());
      return workLog.id;
    }
  }

  Future<List<String>> saveAll(String houseId, List<WorkLog> workLogs) async {
    List<String> ids = [];
    for (var workLog in workLogs) {
      String id = await save(houseId, workLog);
      ids.add(id);
    }
    return ids;
  }

  Future<WorkLog?> getById(String houseId, String id) async {
    DocumentSnapshot doc = await _getWorkLogsCollection(houseId).doc(id).get();
    if (doc.exists) {
      return WorkLog.fromFirestore(doc);
    }
    return null;
  }

  Future<List<WorkLog>> getAll(String houseId) async {
    QuerySnapshot querySnapshot = await _getWorkLogsCollection(houseId).get();
    return querySnapshot.docs.map((doc) => WorkLog.fromFirestore(doc)).toList();
  }

  Future<bool> delete(String houseId, String id) async {
    try {
      await _getWorkLogsCollection(houseId).doc(id).delete();
      return true;
    } catch (e) {
      _logger.warning('ワークログ削除エラー', e);
      return false;
    }
  }

  Future<void> deleteAll(String houseId) async {
    QuerySnapshot querySnapshot = await _getWorkLogsCollection(houseId).get();
    WriteBatch batch = _firestore.batch();

    for (var doc in querySnapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  Future<List<WorkLog>> getIncompleteWorkLogs(String houseId) async {
    QuerySnapshot querySnapshot =
        await _getWorkLogsCollection(houseId)
            .where('isCompleted', isEqualTo: false)
            .orderBy('priority', descending: true)
            .get();

    return querySnapshot.docs.map((doc) => WorkLog.fromFirestore(doc)).toList();
  }

  Stream<List<WorkLog>> getCompletedWorkLogs(String houseId) {
    return _getWorkLogsCollection(houseId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => WorkLog.fromFirestore(doc)).toList(),
        );
  }

  Future<List<WorkLog>> getWorkLogsByUser(String houseId, String userId) async {
    // createdByまたはcompletedByがuserIdに一致するワークログを取得
    QuerySnapshot createdBySnapshot =
        await _getWorkLogsCollection(
          houseId,
        ).where('createdBy', isEqualTo: userId).get();

    QuerySnapshot completedBySnapshot =
        await _getWorkLogsCollection(
          houseId,
        ).where('completedBy', isEqualTo: userId).get();

    // 結果をマージして重複を排除
    Set<String> processedIds = {};
    List<WorkLog> workLogs = [];

    for (var doc in createdBySnapshot.docs) {
      if (!processedIds.contains(doc.id)) {
        workLogs.add(WorkLog.fromFirestore(doc));
        processedIds.add(doc.id);
      }
    }

    for (var doc in completedBySnapshot.docs) {
      if (!processedIds.contains(doc.id)) {
        workLogs.add(WorkLog.fromFirestore(doc));
        processedIds.add(doc.id);
      }
    }

    return workLogs;
  }

  Future<List<WorkLog>> getSharedWorkLogs(String houseId) async {
    QuerySnapshot querySnapshot =
        await _getWorkLogsCollection(houseId)
            .where('isShared', isEqualTo: true)
            .orderBy('priority', descending: true)
            .get();

    return querySnapshot.docs.map((doc) => WorkLog.fromFirestore(doc)).toList();
  }

  Future<List<WorkLog>> getRecurringWorkLogs(String houseId) async {
    QuerySnapshot querySnapshot =
        await _getWorkLogsCollection(houseId)
            .where('isRecurring', isEqualTo: true)
            .orderBy('priority', descending: true)
            .get();

    return querySnapshot.docs.map((doc) => WorkLog.fromFirestore(doc)).toList();
  }

  Future<void> completeWorkLog(
    String houseId,
    WorkLog workLog,
    String userId,
  ) async {
    // freezedモデルはイミュータブルなので、copyWithを使用して新しいインスタンスを作成
    final completedWorkLog = workLog.copyWith(
      isCompleted: true,
      completedAt: DateTime.now(),
      completedBy: userId,
    );

    await _getWorkLogsCollection(
      houseId,
    ).doc(workLog.id).update(completedWorkLog.toFirestore());
  }

  Future<List<WorkLog>> getWorkLogsByTitle(String houseId, String title) async {
    QuerySnapshot querySnapshot =
        await _getWorkLogsCollection(houseId)
            .where('title', isEqualTo: title)
            .orderBy('createdAt', descending: true)
            .get();

    return querySnapshot.docs.map((doc) => WorkLog.fromFirestore(doc)).toList();
  }

  // 権限チェック用のメソッド
  Future<bool> hasPermission(String houseId, String userId) async {
    DocumentSnapshot permissionDoc =
        await _firestore
            .collection('permissions')
            .doc(houseId)
            .collection('admin')
            .doc(userId)
            .get();

    return permissionDoc.exists;
  }
}
