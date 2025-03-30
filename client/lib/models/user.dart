import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';

@freezed
abstract class User with _$User {
  const factory User({
    required String id,
    required String uid,
    required String name,
    required String email,
    required List<String> householdIds,
    required DateTime createdAt,
    @Default(false) bool isPremium,
  }) = _User;
  const User._();

  // Firestoreからのデータ変換
  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return User(
      id: doc.id,
      uid: data['uid']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      householdIds:
          (data['householdIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isPremium: data['isPremium'] as bool? ?? false,
    );
  }

  // FirestoreへのデータマッピングのためのMap
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'householdIds': householdIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'isPremium': isPremium,
    };
  }
}
