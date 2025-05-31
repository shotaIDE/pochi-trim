import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pochi_trim/data/definition/app_definition.dart';
import 'package:pochi_trim/data/model/purchasable.dart';
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

  if (customerInfo.entitlements.active[revenueCatProEntitlementId] == null) {
    throw const PurchaseException.uncategorized();
  }

  await ref.read(currentAppSessionProvider.notifier).upgradeToPro();
}
