import 'dart:async';

import 'package:pochi_trim/data/definition/app_definition.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'in_app_purchase_service.g.dart';

@riverpod
class IsProUser extends _$IsProUser {
  @override
  Stream<bool> build() async* {
    final customerInfo = await Purchases.getCustomerInfo();
    final hasProEntitlement = await _hasProEntitlement(
      customerInfo: customerInfo,
    );
    yield hasProEntitlement;

    final controller = StreamController<bool>();

    Future<void> customerInfoUpdateListener(CustomerInfo info) async {
      final hasProEntitlement = await _hasProEntitlement(customerInfo: info);
      controller.add(hasProEntitlement);
    }

    Purchases.addCustomerInfoUpdateListener(customerInfoUpdateListener);

    ref.onDispose(() {
      Purchases.removeCustomerInfoUpdateListener(customerInfoUpdateListener);
      controller.close();
    });

    yield* controller.stream;
  }

  /// プロユーザーか否かを手動で設定する
  ///
  /// このメソッドは、本番環境のサービスでは意図的に実装されていません。
  /// デバッグやテストの目的で処理されることを目的としています。
  Future<void> setProUser({required bool isPro}) {
    throw UnimplementedError(
      'setProUser is not implemented in the real implementation',
    );
  }

  Future<bool> _hasProEntitlement({required CustomerInfo customerInfo}) async {
    return hasProEntitlement(customerInfo: customerInfo);
  }
}

/// Pro版のエンタイトルメントがアクティブかチェックする
///
/// [customerInfo] を基にPro版のエンタイトルメントがアクティブかどうかを判定します。
bool hasProEntitlement({required CustomerInfo customerInfo}) {
  final entitlementInfo =
      customerInfo.entitlements.active[revenueCatProEntitlementId];
  return entitlementInfo != null;
}
