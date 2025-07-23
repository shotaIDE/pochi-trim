import 'package:flutter/services.dart';
import 'package:pochi_trim/data/model/purchasable.dart';
import 'package:pochi_trim/data/service/in_app_purchase_service.dart';
import 'package:pochi_trim/ui/feature/pro/purchase_exception.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pro_purchase_presenter.g.dart';

/// 購入処理の状態
enum PurchaseStatus {
  /// 何も実行していない
  none,

  /// 購入中
  inPurchasing,

  /// 復元中
  inRestoring,
}

/// 現在の購入処理状態を管理する
@riverpod
class CurrentPurchaseStatus extends _$CurrentPurchaseStatus {
  @override
  PurchaseStatus build() => PurchaseStatus.none;

  /// Pro版を購入する
  ///
  /// 購入に失敗した場合は、[PurchaseException]を投げる。
  Future<void> purchase(Purchasable product) async {
    state = PurchaseStatus.inPurchasing;

    final CustomerInfo customerInfo;
    try {
      final purchaseResult = await Purchases.purchasePackage(product.package);
      customerInfo = purchaseResult.customerInfo;
    } on PlatformException catch (e) {
      state = PurchaseStatus.none;
      final errorCode = PurchasesErrorHelper.getErrorCode(e);

      switch (errorCode) {
        case PurchasesErrorCode.purchaseCancelledError:
          throw const PurchaseException.cancelled();
        // ignore: no_default_cases
        default:
          throw const PurchaseException.uncategorized();
      }
    }

    if (!hasProEntitlement(customerInfo: customerInfo)) {
      state = PurchaseStatus.none;
      throw const PurchaseException.uncategorized();
    }

    state = PurchaseStatus.none;
  }

  /// 購入履歴を復元する
  ///
  /// 復元に失敗した場合は、[RestorePurchaseException]を投げる。
  Future<void> restore() async {
    state = PurchaseStatus.inRestoring;

    final CustomerInfo customerInfo;
    try {
      customerInfo = await Purchases.restorePurchases();
    } on PlatformException catch (e) {
      state = PurchaseStatus.none;
      final errorCode = PurchasesErrorHelper.getErrorCode(e);

      switch (errorCode) {
        case PurchasesErrorCode.invalidReceiptError:
          throw const RestorePurchaseException.notFound();
        // ignore: no_default_cases
        default:
          throw const PurchaseException.uncategorized();
      }
    }

    // Pro版のエンタイトルメントがアクティブかチェック
    if (!hasProEntitlement(customerInfo: customerInfo)) {
      throw const RestorePurchaseException.notFound();
    }

    state = PurchaseStatus.none;
  }
}
