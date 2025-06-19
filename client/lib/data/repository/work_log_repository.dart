import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:pochi_trim/data/model/app_session.dart';
import 'package:pochi_trim/data/model/delete_work_log_exception.dart';
import 'package:pochi_trim/data/model/no_house_id_error.dart';
import 'package:pochi_trim/data/model/save_work_log_exception.dart';
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

  // 家事ログの取得期間（過去1ヶ月）
  static const _workLogRetentionPeriod = Duration(days: 31);

  // ハウスIDを指定して家事ログコレクションの参照を取得
  CollectionReference _getWorkLogsCollection() {
    return FirebaseFirestore.instance
        .collection('houses')
        .doc(_houseId)
        .collection('workLogs');
  }

  /// 家事ログを保存する
  ///
  /// Throws:
  ///   - [SaveWorkLogException] - Firebaseエラー、ネットワークエラー、
  ///     権限エラーなどで保存に失敗した場合
  Future<String> save(WorkLog workLog) async {
    try {
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
    } on FirebaseException catch (e) {
      _logger.warning('家事ログ保存エラー', e);

      throw const SaveWorkLogException();
    }
  }

  /// 家事ログを全て取得する（過去1ヶ月のみ）
  Future<List<WorkLog>> getAllOnce() async {
    // 保持期間の開始日時を計算
    final retentionStartDate = _systemService.getCurrentDateTime().subtract(
      _workLogRetentionPeriod,
    );

    final querySnapshot = await _getWorkLogsCollection()
        .where(
          'completedAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(retentionStartDate),
        )
        .orderBy('completedAt', descending: true)
        .get();
    return querySnapshot.docs.map(WorkLog.fromFirestore).toList();
  }

  /// 家事ログを削除する
  ///
  /// Throws:
  ///   - [DeleteWorkLogException] - Firebaseエラー、ネットワークエラー、
  ///     権限エラーなどで削除に失敗した場合
  Future<void> delete(String id) async {
    try {
      await _getWorkLogsCollection().doc(id).delete();
    } on FirebaseException catch (e) {
      _logger.warning('家事ログ削除エラー', e);

      throw const DeleteWorkLogException();
    }
  }

  /// 完了済みの家事ログを取得するストリーム（過去1ヶ月のみ）
  Stream<List<WorkLog>> getCompletedWorkLogs() {
    // 保持期間の開始日時を計算
    final retentionStartDate = _systemService.getCurrentDateTime().subtract(
      _workLogRetentionPeriod,
    );

    return _getWorkLogsCollection()
        .where(
          'completedAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(retentionStartDate),
        )
        .orderBy('completedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(WorkLog.fromFirestore).toList());
  }
}
