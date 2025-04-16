import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/models/work_log.dart';
import 'package:logging/logging.dart';

final _logger = Logger('WorkLogRepository');

final workLogRepositoryProvider = Provider<WorkLogRepository>((ref) {
  return WorkLogRepository();
});

/// 家事ログリポジトリ
/// 家事の実行記録を管理するためのリポジトリ
class WorkLogRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ハウスIDを指定して家事ログコレクションの参照を取得
  CollectionReference _getWorkLogsCollection(String houseId) {
    return _firestore.collection('houses').doc(houseId).collection('workLogs');
  }

  /// 家事ログを保存する
  Future<String> save(String houseId, WorkLog workLog) async {
    final workLogsCollection = _getWorkLogsCollection(houseId);

    if (workLog.id.isEmpty) {
      // 新規家事ログの場合
      final docRef = await workLogsCollection.add(workLog.toFirestore());
      return docRef.id;
    } else {
      // 既存家事ログの更新
      await workLogsCollection.doc(workLog.id).update(workLog.toFirestore());
      return workLog.id;
    }
  }

  /// 複数の家事ログを一括保存する
  Future<List<String>> saveAll(String houseId, List<WorkLog> workLogs) async {
    final ids = <String>[];
    for (final workLog in workLogs) {
      final id = await save(houseId, workLog);
      ids.add(id);
    }
    return ids;
  }

  /// IDを指定して家事ログを取得する
  Future<WorkLog?> getById(String houseId, String id) async {
    final doc = await _getWorkLogsCollection(houseId).doc(id).get();
    if (doc.exists) {
      return WorkLog.fromFirestore(doc);
    }
    return null;
  }

  /// すべての家事ログを取得する
  Future<List<WorkLog>> getAll(String houseId) async {
    final querySnapshot = await _getWorkLogsCollection(houseId).get();
    return querySnapshot.docs.map(WorkLog.fromFirestore).toList();
  }

  /// 家事ログを削除する
  Future<bool> delete(String houseId, String id) async {
    try {
      await _getWorkLogsCollection(houseId).doc(id).delete();
      return true;
    } on FirebaseException catch (e) {
      _logger.warning('家事ログ削除エラー', e);
      return false;
    }
  }

  /// すべての家事ログを削除する
  Future<void> deleteAll(String houseId) async {
    final querySnapshot = await _getWorkLogsCollection(houseId).get();
    final batch = _firestore.batch();

    for (final doc in querySnapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  /// 特定の家事に関連する家事ログを取得する
  Future<List<WorkLog>> getWorkLogsByHouseWork(
    String houseId,
    String houseWorkId,
  ) async {
    final querySnapshot =
        await _getWorkLogsCollection(houseId)
            .where('houseWorkId', isEqualTo: houseWorkId)
            .orderBy('completedAt', descending: true)
            .get();

    return querySnapshot.docs.map(WorkLog.fromFirestore).toList();
  }

  /// 特定のユーザーが実行した家事ログを取得する
  Future<List<WorkLog>> getWorkLogsByUser(String houseId, String userId) async {
    final querySnapshot =
        await _getWorkLogsCollection(houseId)
            .where('completedBy', isEqualTo: userId)
            .orderBy('completedAt', descending: true)
            .get();

    return querySnapshot.docs.map(WorkLog.fromFirestore).toList();
  }

  /// 最新の家事ログを取得するストリーム
  Stream<List<WorkLog>> getRecentWorkLogs(String houseId, {int limit = 20}) {
    return _getWorkLogsCollection(houseId)
        .orderBy('completedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(WorkLog.fromFirestore).toList());
  }

  /// 特定の期間内の家事ログを取得する
  Future<List<WorkLog>> getWorkLogsByDateRange(
    String houseId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final querySnapshot =
        await _getWorkLogsCollection(houseId)
            .where(
              'completedAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
            )
            .where(
              'completedAt',
              isLessThanOrEqualTo: Timestamp.fromDate(endDate),
            )
            .orderBy('completedAt', descending: true)
            .get();

    return querySnapshot.docs.map(WorkLog.fromFirestore).toList();
  }

  /// 未完了の家事ログを取得する
  Future<List<WorkLog>> getIncompleteWorkLogs(String houseId) async {
    // 未完了の家事ログを取得するロジックを実装
    // 例: 特定のフラグが立っていないものを取得
    final querySnapshot =
        await _getWorkLogsCollection(houseId)
            // TODO(ide): 未完了の条件を指定
            .orderBy('completedAt', descending: false)
            .get();

    return querySnapshot.docs.map(WorkLog.fromFirestore).toList();
  }

  /// 完了済みの家事ログを取得するストリーム
  Stream<List<WorkLog>> getCompletedWorkLogs(String houseId) {
    return _getWorkLogsCollection(houseId)
        .orderBy('completedAt', descending: true)
        .limit(50) // 最新の50件に制限
        .snapshots()
        .map((snapshot) => snapshot.docs.map(WorkLog.fromFirestore).toList());
  }

  /// タイトルで家事ログを検索する
  Future<List<WorkLog>> getWorkLogsByTitle(String houseId, String title) async {
    // タイトルで家事ログを検索するロジック
    final querySnapshot =
        await _getWorkLogsCollection(houseId)
            .where('title', isEqualTo: title)
            .orderBy('completedAt', descending: true)
            .get();

    return querySnapshot.docs.map(WorkLog.fromFirestore).toList();
  }

  /// 家事ログを完了としてマークする
  Future<String> completeWorkLog(
    String houseId,
    WorkLog workLog,
    String userId,
  ) {
    // 家事ログを完了としてマークするロジック
    final updatedWorkLog = WorkLog(
      id: workLog.id,
      houseWorkId: workLog.houseWorkId,
      completedAt: DateTime.now(), // 現在時刻を完了時刻として設定
      completedBy: userId, // 完了したユーザーのIDを設定
    );

    return save(houseId, updatedWorkLog);
  }
}
