import 'package:freezed_annotation/freezed_annotation.dart';

part 'add_house_work_args.freezed.dart';

@freezed
abstract class AddHouseWorkArgs with _$AddHouseWorkArgs {
  const factory AddHouseWorkArgs({
    required String title,
    required String icon,
    required DateTime createdAt,
    required String createdBy,
  }) = _AddHouseWorkArgs;

  const AddHouseWorkArgs._();

  // FirestoreへのデータマッピングのためのMap
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'icon': icon,
      // `DateTime` インスタンスはそのままFirestoreに渡すことで、Firestore側でタイムスタンプ型として保持させる
      'createdAt': createdAt,
      'createdBy': createdBy,
    };
  }
}
