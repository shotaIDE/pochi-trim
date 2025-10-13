import 'package:pochi_trim/data/model/purchasable.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'revenue_cat_service.g.dart';

@riverpod
Future<List<Purchasable>?> currentPurchasables(Ref ref) async {
  final offerings = await Purchases.getOfferings();
  final currentOffering = offerings.current;
  if (currentOffering == null) {
    return null;
  }

  final availablePackages = currentOffering.availablePackages;
  return availablePackages.map(PurchasableGenerator.fromPackage).toList();
}
