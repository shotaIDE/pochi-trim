import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import 'package:pochi_trim/data/model/add_work_log_exception.dart';
import 'package:pochi_trim/data/model/delete_work_log_exception.dart';
import 'package:pochi_trim/data/model/update_work_log_exception.dart';
import 'package:pochi_trim/data/model/work_log.dart';
import 'package:pochi_trim/data/repository/dao/add_work_log_args.dart';
import 'package:pochi_trim/data/repository/house_repository.dart';
import 'package:pochi_trim/data/service/error_report_service.dart';
import 'package:pochi_trim/data/service/system_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'work_log_repository.g.dart';

final _logger = Logger('WorkLogRepository');

@riverpod
WorkLogRepository workLogRepository(Ref ref) {
  final currentHouseId = ref.watch(unwrappedCurrentHouseIdProvider);
  final systemService = ref.watch(systemServiceProvider);
  final errorReportService = ref.watch(errorReportServiceProvider);

  return WorkLogRepository(
    houseId: currentHouseId,
    systemService: systemService,
    errorReportService: errorReportService,
  );
}

class WorkLogRepository {
  WorkLogRepository({
    required String houseId,
    required SystemService systemService,
    required ErrorReportService errorReportService,
  }) : _houseId = houseId,
       _systemService = systemService,
       _errorReportService = errorReportService;

  final String _houseId;
  final SystemService _systemService;
  final ErrorReportService _errorReportService;

  // 家事ログの取得期間（過去1ヶ月）
  static const _workLogRetentionPeriod = Duration(days: 31);

  // ハウスIDを指定して家事ログコレクションの参照を取得
  CollectionReference _getWorkLogsCollection() {
    return FirebaseFirestore.instance
        .collection('houses')
        .doc(_houseId)
        .collection('workLogs');
  }

  /// 新しい家事ログを追加する
  ///
  /// Throws:
  ///   - [AddWorkLogException] - Firebaseエラー、ネットワークエラー、
  ///     権限エラーなどで保存に失敗した場合
  Future<String> add(AddWorkLogArgs args) async {
    try {
      final workLogsCollection = _getWorkLogsCollection();
      final docRef = await workLogsCollection.add(args.toFirestore());
      return docRef.id;
    } on FirebaseException catch (e, stack) {
      _logger.warning('家事ログ追加エラー', e);

      unawaited(_errorReportService.recordError(e, stack));

      throw const AddWorkLogException();
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
    } on FirebaseException catch (e, stack) {
      _logger.warning('家事ログ削除エラー', e);

      unawaited(_errorReportService.recordError(e, stack));

      throw const DeleteWorkLogException();
    }
  }

  /// 家事ログの完了時刻を更新する
  ///
  /// Throws:
  ///   - [UpdateWorkLogException.uncategorized] - Firebaseエラー、ネットワークエラー、
  ///     権限エラーなどで更新に失敗した場合
  Future<void> updateCompletedAt(
    String id, {
    required DateTime completedAt,
  }) async {
    try {
      await _getWorkLogsCollection().doc(id).update({
        'completedAt': completedAt,
      });
    } on FirebaseException catch (e, stack) {
      _logger.warning('Failed to update work log', e);

      unawaited(_errorReportService.recordError(e, stack));

      throw const UpdateWorkLogException.uncategorized();
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
