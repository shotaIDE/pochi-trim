import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:pochi_trim/data/model/preference_key.dart';
import 'package:pochi_trim/data/repository/house_work_repository.dart';
import 'package:pochi_trim/data/repository/work_log_repository.dart';
import 'package:pochi_trim/data/service/preference_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'review_service.g.dart';

@riverpod
ReviewService reviewService(Ref ref) {
  final preferenceService = ref.watch<PreferenceService>(
    preferenceServiceProvider,
  );
  final houseWorkRepository = ref.watch(houseWorkRepositoryProvider);
  final workLogRepository = ref.watch(workLogRepositoryProvider);
  return ReviewService(
    preferenceService: preferenceService,
    houseWorkRepository: houseWorkRepository,
    workLogRepository: workLogRepository,
  );
}

/// ストアレビューを促進するサービス
class ReviewService {
  ReviewService({
    required this.preferenceService,
    required this.houseWorkRepository,
    required this.workLogRepository,
  });

  final PreferenceService preferenceService;
  final HouseWorkRepository houseWorkRepository;
  final WorkLogRepository workLogRepository;

  /// レビューリクエストが可能かどうかを確認
  static const _reviewRequestThresholds = [5, 15, 30];

  /// アハ・モーメントに基づいてレビューを促進する
  ///
  /// 家事ログの完了数が特定の閾値（5、15、30個）に達した場合、
  /// まだレビューをリクエストしていない場合にレビューダイアログを表示します。
  Future<void> checkAndRequestReview({
    required int totalWorkLogCount,
  }) async {
    // 既にレビューをリクエストしているかチェック
    final hasRequestedReview = await preferenceService.getBool(
          PreferenceKey.hasRequestedReview,
        ) ??
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

  /// 分析画面表示後のレビューリクエストをチェック
  ///
  /// 以下の条件を満たす場合にレビューを促進：
  /// - 3種類以上の家事が登録されている
  /// - 10回以上の家事ログが存在する
  /// - 分析画面を表示済み
  /// - まだレビューリクエストしていない
  Future<void> checkAndRequestReviewAfterAnalysis() async {
    // 既にレビューをリクエストしているかチェック
    final hasRequestedReview = await preferenceService.getBool(
          PreferenceKey.hasRequestedReview,
        ) ??
        false;
    if (hasRequestedReview) {
      return;
    }

    // 分析画面を表示済みかチェック
    final hasViewedAnalysisScreen = await preferenceService.getBool(
          PreferenceKey.hasViewedAnalysisScreen,
        ) ??
        false;
    if (!hasViewedAnalysisScreen) {
      return;
    }

    try {
      // 家事の種類数をチェック
      final houseWorks = await houseWorkRepository.getAllOnce();
      if (houseWorks.length < 3) {
        return;
      }

      // 家事ログの総数をチェック
      final workLogs = await workLogRepository.getAllOnce();
      if (workLogs.length < 10) {
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
    } on Exception {
      // エラーが発生してもレビューチェックの失敗として扱い、
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
