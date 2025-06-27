import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'in_app_review_service.g.dart';

@riverpod
InAppReviewService inAppReviewService(Ref ref) {
  return InAppReviewService();
}

/// ストアレビューを促進するサービス
class InAppReviewService {
  InAppReviewService();

  /// レビューをリクエスト
  Future<void> requestReview() async {
    final inAppReview = InAppReview.instance;

    if (!await inAppReview.isAvailable()) {
      return;
    }

    await inAppReview.requestReview();
  }
}
