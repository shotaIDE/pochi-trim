import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/data/model/app_session.dart';
import 'package:house_worker/data/model/no_house_id_error.dart';
import 'package:house_worker/data/model/work_log.dart';
import 'package:house_worker/ui/root_presenter.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'work_log_repository.g.dart';

final _logger = Logger('WorkLogRepository');

@riverpod
WorkLogRepository workLogRepository(Ref ref) {
  final appSession = ref.watch(unwrappedCurrentAppSessionProvider);

  switch (appSession) {
    case AppSessionSignedIn(currentHouseId: final currentHouseId):
      return WorkLogRepository(houseId: currentHouseId);
    case AppSessionNotSignedIn():
      throw NoHouseIdError();
  }
}

class WorkLogRepository {
  WorkLogRepository({required String houseId}) : _houseId = houseId;

  final String _houseId;

  // ハウスIDを指定して家事ログコレクションの参照を取得
  CollectionReference _getWorkLogsCollection() {
    return FirebaseFirestore.instance
        .collection('houses')
        .doc(_houseId)
        .collection('workLogs');
  }

  /// 家事ログを保存する
  Future<String> save(WorkLog workLog) async {
    final workLogsCollection = _getWorkLogsCollection();

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
  Future<List<String>> saveAll(List<WorkLog> workLogs) async {
    final ids = <String>[];
    for (final workLog in workLogs) {
      final id = await save(workLog);
      ids.add(id);
    }
    return ids;
  }

  /// IDを指定して家事ログを取得する
  Future<WorkLog?> getById(String id) async {
    final doc = await _getWorkLogsCollection().doc(id).get();
    if (doc.exists) {
      return WorkLog.fromFirestore(doc);
    }
    return null;
  }

  Future<List<WorkLog>> getAllOnce() async {
    final querySnapshot = await _getWorkLogsCollection().get();
    return querySnapshot.docs.map(WorkLog.fromFirestore).toList();
  }

  /// 家事ログを削除する
  Future<bool> delete(String id) async {
    try {
      await _getWorkLogsCollection().doc(id).delete();
      return true;
    } on FirebaseException catch (e) {
      _logger.warning('家事ログ削除エラー', e);
      return false;
    }
  }

  /// すべての家事ログを削除する
  Future<void> deleteAll() async {
    final querySnapshot = await _getWorkLogsCollection().get();
    final batch = FirebaseFirestore.instance.batch();

    for (final doc in querySnapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  /// 特定の家事に関連する家事ログを取得する
  Future<List<WorkLog>> getWorkLogsByHouseWork(String houseWorkId) async {
    final querySnapshot =
        await _getWorkLogsCollection()
            .where('houseWorkId', isEqualTo: houseWorkId)
            .orderBy('completedAt', descending: true)
            .get();

    return querySnapshot.docs.map(WorkLog.fromFirestore).toList();
  }

  /// 特定のユーザーが実行した家事ログを取得する
  Future<List<WorkLog>> getWorkLogsByUser(String userId) async {
    final querySnapshot =
        await _getWorkLogsCollection()
            .where('completedBy', isEqualTo: userId)
            .orderBy('completedAt', descending: true)
            .get();

    return querySnapshot.docs.map(WorkLog.fromFirestore).toList();
  }

  /// 最新の家事ログを取得するストリーム
  Stream<List<WorkLog>> getRecentWorkLogs({int limit = 20}) {
    return _getWorkLogsCollection()
        .orderBy('completedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(WorkLog.fromFirestore).toList());
  }

  /// 特定の期間内の家事ログを取得する
  Future<List<WorkLog>> getWorkLogsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final querySnapshot =
        await _getWorkLogsCollection()
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

  /// 完了済みの家事ログを取得するストリーム
  Stream<List<WorkLog>> getCompletedWorkLogs() {
    return _getWorkLogsCollection()
        .orderBy('completedAt', descending: true)
        .limit(50) // 最新の50件に制限
        .snapshots()
        .map((snapshot) => snapshot.docs.map(WorkLog.fromFirestore).toList());
  }

  /// タイトルで家事ログを検索する
  Future<List<WorkLog>> getWorkLogsByTitle(String title) async {
    // タイトルで家事ログを検索するロジック
    final querySnapshot =
        await _getWorkLogsCollection()
            .where('title', isEqualTo: title)
            .orderBy('completedAt', descending: true)
            .get();

    return querySnapshot.docs.map(WorkLog.fromFirestore).toList();
  }

  /// 家事ログを完了としてマークする
  Future<String> completeWorkLog(WorkLog workLog, String userId) {
    // 家事ログを完了としてマークするロジック
    final updatedWorkLog = WorkLog(
      id: workLog.id,
      houseWorkId: workLog.houseWorkId,
      completedAt: DateTime.now(), // 現在時刻を完了時刻として設定
      completedBy: userId, // 完了したユーザーのIDを設定
    );

    return save(updatedWorkLog);
  }
}
