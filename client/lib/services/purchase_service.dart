import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/exceptions/purchase_exception.dart';
import 'package:house_worker/root_app_session.dart';
import 'package:house_worker/root_presenter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'purchase_service.g.dart';

@riverpod
PurchaseService purchaseService(Ref ref) {
  return PurchaseService(ref);
}

/// Pro版の購入処理を行うサービスクラス
class PurchaseService {
  PurchaseService(this._ref);
  final Ref _ref;

  /// Pro版を購入する
  ///
  /// 成功時はtrue、失敗時はfalseを返す
  Future<bool> purchasePro() async {
    try {
      // TODO(ide): RevenueCatを使用して課金処理を実行
      // 現在はRevenueCatのライブラリがないため、モック実装
      // 実際の実装では以下のようなコードになる
      // final purchaseResult = await Purchases.purchaseProduct('pro_version');
      // if (purchaseResult.customerInfo.entitlements.active.containsKey('pro_access')) {
      //   // 課金成功時の処理
      // }

      // TODO(ide): モック実装。常に成功するとする
      const success = true;

      if (success) {
        // アプリケーションのセッション状態を更新
        final appSession = _ref.read(rootAppInitializedProvider);
        if (appSession is AppSessionSignedIn) {
          await _ref.read(rootAppInitializedProvider.notifier).upgradeToPro();
        }

        return true;
      }
    } catch (e) {
      // エラーハンドリング
      throw PurchaseException();
    }

    return false;
  }

  /// 現在のPro版の状態を取得する
  bool isPremium() {
    // TODO(ide): purchases_flutter を使用してPro版の状態を取得
    final appSession = _ref.read(rootAppInitializedProvider);
    return switch (appSession) {
      AppSessionSignedIn(:final isPremium) => isPremium,
      _ => false,
    };
  }
}
