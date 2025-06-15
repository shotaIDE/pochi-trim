import 'package:freezed_annotation/freezed_annotation.dart';

part 'delete_house_work_exception.freezed.dart';

/// 家事削除時に発生するException
@freezed
class DeleteHouseWorkException
    with _$DeleteHouseWorkException
    implements Exception {
  const factory DeleteHouseWorkException({
    /// エラーメッセージ
    String? message,
    /// 元のエラーコード（Firebase Functionsのエラーコード等）
    String? errorCode,
  }) = _DeleteHouseWorkException;
}