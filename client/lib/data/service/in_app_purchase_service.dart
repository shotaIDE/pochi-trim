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

  void setProUser({required bool isPro}) {
    throw UnimplementedError(
      'setProUser is not implemented in the real implementation',
    );
  }

  Future<bool> _hasProEntitlement({required CustomerInfo customerInfo}) async {
    final entitlementInfo =
        customerInfo.entitlements.active[revenueCatProEntitlementId];
    return entitlementInfo != null;
  }
}
