import 'package:pochi_trim/data/model/feedback_request.dart';
import 'package:pochi_trim/data/model/send_feedback_exception.dart';
import 'package:pochi_trim/data/service/google_form_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'submit_feedback_presenter.g.dart';

@riverpod
class IsSubmissionAvailable extends _$IsSubmissionAvailable {
  @override
  bool build() => true;

  /// ご意見•ご要望を送信する
  ///
  /// Throws:
  /// - [SendFeedbackException]: ご意見•ご要望送信に失敗した場合
  Future<void> submitFeedback(FeedbackRequest request) async {
    state = false;

    final googleFormService = ref.read(googleFormServiceProvider);

    try {
      await googleFormService.sendFeedback(request);
    } finally {
      state = true;
    }
  }
}
