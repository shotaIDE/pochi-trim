import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pochi_trim/data/definition/app_definition.dart';
import 'package:pochi_trim/data/model/app_session.dart';
import 'package:pochi_trim/data/model/purchasable.dart';
import 'package:pochi_trim/ui/feature/pro/purchase_exception.dart';
import 'package:pochi_trim/ui/root_presenter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pro_purchase_presenter.g.dart';

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

  if (customerInfo.entitlements.active[revenueCatProEntitlementId] != null) {
    final appSession = ref.read(unwrappedCurrentAppSessionProvider);
    if (appSession is AppSessionSignedIn) {
      await ref.read(currentAppSessionProvider.notifier).upgradeToPro();
    }
  } else {
    // TODO(ide): 実装
  }
}
