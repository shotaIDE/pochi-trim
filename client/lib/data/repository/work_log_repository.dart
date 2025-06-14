import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:pochi_trim/data/model/app_session.dart';
import 'package:pochi_trim/data/model/no_house_id_error.dart';
import 'package:pochi_trim/data/model/work_log.dart';
import 'package:pochi_trim/data/service/system_service.dart';
import 'package:pochi_trim/ui/root_presenter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'work_log_repository.g.dart';

final _logger = Logger('WorkLogRepository');

@riverpod
WorkLogRepository workLogRepository(Ref ref) {
  final appSession = ref.watch(unwrappedCurrentAppSessionProvider);
  final systemService = ref.watch(systemServiceProvider);

  switch (appSession) {
    case AppSessionSignedIn(currentHouseId: final currentHouseId):
      return WorkLogRepository(
        houseId: currentHouseId,
        systemService: systemService,
      );
    case AppSessionNotSignedIn():
      throw NoHouseIdError();
  }
}

class WorkLogRepository {
  WorkLogRepository({
    required String houseId,
    required SystemService systemService,
  }) : _houseId = houseId,
       _systemService = systemService;

  final String _houseId;
  final SystemService _systemService;

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

  /// 家事ログを全て取得する（過去1ヶ月のみ）
  Future<List<WorkLog>> getAllOnce() async {
    // 過去1ヶ月の開始日時を計算
    final oneMonthAgo = _systemService.getCurrentDateTime().subtract(
      const Duration(days: 30),
    );

    final querySnapshot = await _getWorkLogsCollection()
        .where(
          'completedAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(oneMonthAgo),
        )
        .orderBy('completedAt', descending: true)
        .get();
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

  /// 特定の期間内の家事ログを取得する
  Future<List<WorkLog>> getWorkLogsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final querySnapshot = await _getWorkLogsCollection()
        .where(
          'completedAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        )
        .where('completedAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('completedAt', descending: true)
        .get();

    return querySnapshot.docs.map(WorkLog.fromFirestore).toList();
  }

  /// 完了済みの家事ログを取得するストリーム（過去1ヶ月のみ）
  Stream<List<WorkLog>> getCompletedWorkLogs() {
    // 過去1ヶ月の開始日時を計算
    final oneMonthAgo = _systemService.getCurrentDateTime().subtract(
      const Duration(days: 30),
    );

    return _getWorkLogsCollection()
        .where(
          'completedAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(oneMonthAgo),
        )
        .orderBy('completedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(WorkLog.fromFirestore).toList());
  }
}
