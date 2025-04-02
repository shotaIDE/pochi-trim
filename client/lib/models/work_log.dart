import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'work_log.freezed.dart';
part 'work_log.g.dart';

/// 家事ログモデル
/// 家事の実行記録を表現する
@freezed
abstract class WorkLog with _$WorkLog {
  const factory WorkLog({
    required String id,
    required String houseWorkId, // 関連する家事のID
    required DateTime completedAt, // 完了時刻
    required String completedBy, // 実行ユーザー
    String? note, // 実行時のメモ（オプション）
  }) = _WorkLog;

  factory WorkLog.fromJson(Map<String, dynamic> json) =>
      _$WorkLogFromJson(json);

  // Firestoreからのデータ変換
  factory WorkLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return WorkLog(
      id: doc.id,
      houseWorkId: data['houseWorkId']?.toString() ?? '',
      completedAt:
          data['completedAt'] != null
              ? (data['completedAt'] as Timestamp).toDate()
              : DateTime.now(),
      completedBy: data['completedBy']?.toString() ?? '',
      note: data['note']?.toString(),
    );
  }

  // FirestoreへのデータマッピングのためのMap
  Map<String, dynamic> toFirestore() {
    return toJson()..remove('id');
  }
}
