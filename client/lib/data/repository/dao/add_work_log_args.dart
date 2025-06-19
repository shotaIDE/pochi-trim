import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pochi_trim/data/model/work_log.dart';

part 'add_work_log_args.freezed.dart';

@freezed
abstract class AddWorkLogArgs with _$AddWorkLogArgs {
  const factory AddWorkLogArgs({
    required String houseWorkId,
    required DateTime completedAt,
    required String completedBy,
  }) = _AddWorkLogArgs;

  const AddWorkLogArgs._();

  /// WorkLogオブジェクトからAddWorkLogArgsを作成する
  factory AddWorkLogArgs.fromWorkLog(WorkLog workLog) {
    return AddWorkLogArgs(
      houseWorkId: workLog.houseWorkId,
      completedAt: workLog.completedAt,
      completedBy: workLog.completedBy,
    );
  }

  // FirestoreへのデータマッピングのためのMap
  Map<String, dynamic> toFirestore() {
    return {
      'houseWorkId': houseWorkId,
      // `DateTime` インスタンスはそのままFirestoreに渡すことで、Firestore側でタイムスタンプ型として保持させる
      'completedAt': completedAt,
      'completedBy': completedBy,
    };
  }
}
