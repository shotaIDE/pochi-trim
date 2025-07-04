import 'package:pochi_trim/data/service/google_form_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'submit_feedback_presenter.g.dart';

@riverpod
class IsSubmittingFeedback extends _$IsSubmittingFeedback {
  @override
  bool build() => false;

  /// フィードバックを送信する
  Future<void> submitFeedback({
    required String feedback,
    String? email,
    String? userId,
  }) async {
    state = true;

    final googleFormService = ref.read(googleFormServiceProvider);

    try {
      await googleFormService.sendFeedback(
        feedback: feedback,
        email: email,
        userId: userId,
      );
    } finally {
      state = false;
    }
  }
}
