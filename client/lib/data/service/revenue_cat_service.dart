import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pochi_trim/data/model/purchasable.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'revenue_cat_service.g.dart';

@riverpod
Future<List<Purchasable>?> purchasableProducts(Ref ref) async {
  final offerings = await Purchases.getOfferings();
  final currentOffering = offerings.current;

  if (currentOffering == null) {
    return null;
  }

  final availablePackages = currentOffering.availablePackages;
  return availablePackages
      .map(
        (package) => Purchasable(
          productId: package.storeProduct.identifier,
          title: package.storeProduct.title,
          description: package.storeProduct.description,
          price: package.storeProduct.priceString,
          package: package,
        ),
      )
      .toList();
}
