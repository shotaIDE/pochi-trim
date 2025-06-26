import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:pochi_trim/data/model/preference_key.dart';
import 'package:pochi_trim/data/service/preference_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'review_service.g.dart';

@riverpod
ReviewService reviewService(Ref ref) {
  final preferenceService = ref.watch<PreferenceService>(
    preferenceServiceProvider,
  );
  return ReviewService(preferenceService: preferenceService);
}

/// ストアレビューを促進するサービス
class ReviewService {
  ReviewService({required this.preferenceService});

  final PreferenceService preferenceService;

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

      // レビューをリクエストしたことを記録
      await preferenceService.setBool(
        PreferenceKey.hasRequestedReview,
        value: true,
      );
    } on Exception {
      // エラーが発生してもレビューリクエストの失敗として扱い、
      // アプリの動作には影響させない
    }
  }
}
