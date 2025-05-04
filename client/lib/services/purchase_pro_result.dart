import 'package:house_worker/exceptions/purchase_exception.dart';
import 'package:house_worker/root_app_session.dart';
import 'package:house_worker/root_presenter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'purchase_pro_result.g.dart';

/// Pro版の購入処理を行うサービスクラス
@riverpod
class PurchaseProResult extends _$PurchaseProResult {
  @override
  Future<bool?> build() async {
    return null;
  }

  Future<bool> purchasePro() async {
    final bool isSucceeded;
    try {
      // TODO(ide): RevenueCatを使用して課金処理を実行
      // 現在はRevenueCatのライブラリがないため、モック実装
      // 実際の実装では以下のようなコードになる
      // final purchaseResult = await Purchases.purchaseProduct('pro_version');
      // if (purchaseResult.customerInfo.entitlements.active.containsKey('pro_access')) {
      //   // 課金成功時の処理
      // }

      // TODO(ide): モック実装。常に成功するとする
      isSucceeded = true;
    } catch (e) {
      // エラーハンドリング
      throw PurchaseException();
    }

    if (!isSucceeded) {
      return false;
    }

    // アプリケーションのセッション状態を更新
    final appSession = ref.read(rootAppInitializedProvider);
    if (appSession is AppSessionSignedIn) {
      await ref.read(rootAppInitializedProvider.notifier).upgradeToPro();
    }

    return true;
  }
}
