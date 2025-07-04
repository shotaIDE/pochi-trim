import 'package:pochi_trim/data/model/feedback_request.dart';
import 'package:pochi_trim/data/model/send_feedback_exception.dart';
import 'package:pochi_trim/data/service/google_form_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'submit_feedback_presenter.g.dart';

@riverpod
class IsSubmittingFeedback extends _$IsSubmittingFeedback {
  @override
  bool build() => false;

  /// フィードバックを送信する
  ///
  /// [request] 送信するフィードバックリクエスト
  ///
  /// 送信中は状態を`true`に設定し、完了後は`false`に戻す。
  ///
  /// Throws:
  /// - [SendFeedbackException]: フィードバック送信に失敗した場合
  Future<void> submitFeedback(FeedbackRequest request) async {
    state = true;

    final googleFormService = ref.read(googleFormServiceProvider);

    try {
      await googleFormService.sendFeedback(request);
    } finally {
      state = false;
    }
  }
}
