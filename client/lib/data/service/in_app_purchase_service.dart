import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'in_app_purchase_service.g.dart';

@riverpod
Stream<bool> isProUser(Ref ref) async* {
  final customerInfo = await Purchases.getCustomerInfo();
  final entitlementInfo = customerInfo.entitlements.active['pro'];
  yield entitlementInfo != null;

  final controller = StreamController<bool>();

  void customerInfoUpdateListener(CustomerInfo info) {
    final entitlement = info.entitlements.active['pro'];
    controller.add(entitlement != null);
  }

  Purchases.addCustomerInfoUpdateListener(customerInfoUpdateListener);

  ref.onDispose(() {
    Purchases.removeCustomerInfoUpdateListener(customerInfoUpdateListener);
    controller.close();
  });

  yield* controller.stream;
}
