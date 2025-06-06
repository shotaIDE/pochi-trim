import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pochi_trim/data/model/purchasable.dart';
import 'package:pochi_trim/data/service/in_app_purchase_service.dart';
import 'package:pochi_trim/ui/feature/pro/purchase_exception.dart';
import 'package:pochi_trim/ui/root_presenter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pro_purchase_presenter.g.dart';

/// Pro版を購入する
///
/// 購入に失敗した場合は、[PurchaseException]を投げる。
@riverpod
Future<void> purchaseResult(Ref ref, Purchasable product) async {
  final CustomerInfo customerInfo;
  try {
    customerInfo = await Purchases.purchasePackage(product.package);
  } on PlatformException catch (e) {
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
    throw const PurchaseException.uncategorized();
  }

  await ref.read(currentAppSessionProvider.notifier).upgradeToPro();
}

/// 購入履歴を復元する
///
/// 復元に失敗した場合は、[RestorePurchaseException]を投げる。
@riverpod
Future<void> restorePurchaseResult(Ref ref) async {
  final CustomerInfo customerInfo;
  try {
    customerInfo = await Purchases.restorePurchases();
  } on PlatformException catch (e) {
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
  if (hasProEntitlement(customerInfo: customerInfo)) {
    await ref.read(currentAppSessionProvider.notifier).upgradeToPro();
  }
}
