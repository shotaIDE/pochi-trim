import 'package:freezed_annotation/freezed_annotation.dart';

part 'feedback_request.freezed.dart';

@freezed
abstract class FeedbackRequest with _$FeedbackRequest {
  factory FeedbackRequest({
    required String feedback,
    String? email,
    String? userId,
  }) = _FeedbackRequest;
}
