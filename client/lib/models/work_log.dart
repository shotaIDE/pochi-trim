import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'work_log.freezed.dart';

@freezed
abstract class WorkLog with _$WorkLog {
  const factory WorkLog({
    required String id,
    required String title,
    String? description,
    required String icon,
    required DateTime createdAt,
    DateTime? completedAt,
    required String createdBy,
    String? completedBy,
    required bool isShared,
    required bool isRecurring,
    int? recurringIntervalMs,
    @Default(false) bool isCompleted,
    @Default(0) int priority,
  }) = _WorkLog;

  // Firestoreからのデータ変換
  factory WorkLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return WorkLog(
      id: doc.id,
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString(),
      icon: data['icon']?.toString() ?? '🏠', // デフォルトアイコンを家の絵文字に設定
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      completedAt:
          data['completedAt'] != null
              ? (data['completedAt'] as Timestamp).toDate()
              : null,
      createdBy: data['createdBy']?.toString() ?? '',
      completedBy: data['completedBy']?.toString(),
      isShared: data['isShared'] as bool? ?? false,
      isRecurring: data['isRecurring'] as bool? ?? false,
      recurringIntervalMs: data['recurringIntervalMs'] as int?,
      isCompleted: data['isCompleted'] as bool? ?? false,
      priority: data['priority'] as int? ?? 0, // デフォルト優先度
    );
  }

  const WorkLog._();

  Duration? get recurringInterval =>
      recurringIntervalMs != null
          ? Duration(milliseconds: recurringIntervalMs!)
          : null;

  // FirestoreへのデータマッピングのためのMap
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'icon': icon, // アイコンフィールド
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'createdBy': createdBy,
      'completedBy': completedBy,
      'isShared': isShared,
      'isRecurring': isRecurring,
      'recurringIntervalMs': recurringIntervalMs,
      'isCompleted': isCompleted,
      'priority': priority, // 優先度フィールド
    };
  }
}
