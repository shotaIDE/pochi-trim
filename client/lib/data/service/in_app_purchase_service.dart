import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'in_app_purchase_service.g.dart';

@riverpod
Stream<bool> isProUser(Ref ref) async* {
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

Future<bool> _hasProEntitlement({required CustomerInfo customerInfo}) async {
  final entitlementInfo = customerInfo.entitlements.active['pro'];
  return entitlementInfo != null;
}
