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

  /// レビューリクエストが可能かどうかを確認
  static const _reviewRequestThresholds = [30, 100];

  /// アハ・モーメントに基づいてレビューを促進する
  ///
  /// 家事ログの完了数が特定の閾値（30、100個）に達した場合、
  /// まだレビューをリクエストしていない場合にレビューダイアログを表示します。
  Future<void> checkAndRequestReview({required int totalWorkLogCount}) async {
    // 既にレビューをリクエストしているかチェック
    final hasRequestedReview =
        await preferenceService.getBool(PreferenceKey.hasRequestedReview) ??
        false;
    if (hasRequestedReview) {
      return;
    }

    // 閾値に達しているかチェック
    final shouldRequestReview = _reviewRequestThresholds.contains(
      totalWorkLogCount,
    );
    if (!shouldRequestReview) {
      return;
    }

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
  }

  /// 現在の家事ログ完了数を保存
  Future<void> updateTotalWorkLogCount(int count) async {
    await preferenceService.setString(
      PreferenceKey.totalWorkLogCount,
      value: count.toString(),
    );
  }

  /// 保存された家事ログ完了数を取得
  Future<int> getTotalWorkLogCount() async {
    final countString = await preferenceService.getString(
      PreferenceKey.totalWorkLogCount,
    );
    return int.tryParse(countString ?? '0') ?? 0;
  }

  /// 分析画面を表示したことを記録
  Future<void> markAnalysisScreenViewed() async {
    await preferenceService.setBool(
      PreferenceKey.hasViewedAnalysisScreen,
      value: true,
    );
  }

  /// 既にレビューリクエスト済みかどうかを取得
  Future<bool> hasRequestedReview() async {
    return await preferenceService.getBool(PreferenceKey.hasRequestedReview) ??
        false;
  }

  /// 分析画面を表示済みかどうかを取得
  Future<bool> hasViewedAnalysisScreen() async {
    return await preferenceService.getBool(
          PreferenceKey.hasViewedAnalysisScreen,
        ) ??
        false;
  }

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

  /// レビューリクエスト状態をリセット（デバッグ用）
  Future<void> resetReviewRequestStatus() async {
    await preferenceService.setBool(
      PreferenceKey.hasRequestedReview,
      value: false,
    );
    await preferenceService.setBool(
      PreferenceKey.hasViewedAnalysisScreen,
      value: false,
    );
  }
}
