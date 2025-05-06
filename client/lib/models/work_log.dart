import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'work_log.freezed.dart';

/// 家事ログ
///
/// 家事の実行記録を表現する
@freezed
abstract class WorkLog with _$WorkLog {
  const factory WorkLog({
    required String id,
    required String houseWorkId,
    required DateTime completedAt,
    required String completedBy,
  }) = _WorkLog;

  const WorkLog._();

  factory WorkLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return WorkLog(
      id: doc.id,
      houseWorkId: data['houseWorkId']?.toString() ?? '',
      completedAt: (data['completedAt'] as Timestamp).toDate(),
      completedBy: data['completedBy']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'houseWorkId': houseWorkId,
      // `DateTime` インスタンスはそのままFirestoreに渡すことで、Firestore側でタイムスタンプ型として保持させる
      'completedAt': completedAt,
      'completedBy': completedBy,
    };
  }
}
