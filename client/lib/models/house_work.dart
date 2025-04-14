import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'house_work.freezed.dart';
part 'house_work.g.dart';

/// 家事モデル
/// 家事の基本情報を表現する
@freezed
abstract class HouseWork with _$HouseWork {
  const factory HouseWork({
    required String id,
    required String title,
    String? description,
    required String icon,
    required DateTime createdAt,
    required String createdBy,
    required bool isRecurring,
    int? recurringIntervalMs,
  }) = _HouseWork;

  const HouseWork._();

  factory HouseWork.fromJson(Map<String, dynamic> json) =>
      _$HouseWorkFromJson(json);

  // Firestoreからのデータ変換
  factory HouseWork.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return HouseWork(
      id: doc.id,
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString(),
      icon: data['icon']?.toString() ?? '🏠', // デフォルトアイコンを家の絵文字に設定
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      createdBy: data['createdBy']?.toString() ?? '',
      isRecurring: data['isRecurring'] as bool? ?? false,
      recurringIntervalMs: data['recurringIntervalMs'] as int?,
    );
  }

  // FirestoreへのデータマッピングのためのMap
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'icon': icon,
      'createdAt': createdAt,
      'createdBy': createdBy,
      'isRecurring': isRecurring,
      'recurringIntervalMs': recurringIntervalMs,
    };
  }
}
