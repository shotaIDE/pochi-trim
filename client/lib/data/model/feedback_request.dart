import 'package:freezed_annotation/freezed_annotation.dart';

part 'feedback_request.freezed.dart';

@freezed
abstract class FeedbackRequest with _$FeedbackRequest {
  factory FeedbackRequest({
    required String feedback,
    String? email,
    String? userId,
  }) = _FeedbackRequest;

  const FeedbackRequest._();

  /// Google Formに送信するためのフォームデータに変換する
  Map<String, String> toFormData() {
    return {
      'entry.893089758': feedback,
      if (email != null && email!.isNotEmpty) 'entry.1495718762': email!,
      if (userId != null && userId!.isNotEmpty) 'entry.1274333669': userId!,
    };
  }
}
