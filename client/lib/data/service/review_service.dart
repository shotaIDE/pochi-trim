import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'review_service.g.dart';

@riverpod
ReviewService reviewService(Ref ref) {
  return ReviewService();
}

/// ストアレビューを促進するサービス
class ReviewService {
  ReviewService();

  /// レビューをリクエスト
  Future<void> requestReview() async {
    try {
      // アプリストアでレビューが可能かチェック
      final inAppReview = InAppReview.instance;
      if (!await inAppReview.isAvailable()) {
        return;
      }

      // レビューダイアログを表示
      await inAppReview.requestReview();
    } on Exception {
      // エラーが発生してもレビューリクエストの失敗として扱い、
      // アプリの動作には影響させない
    }
  }
}
