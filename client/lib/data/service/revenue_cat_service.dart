import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pochi_trim/data/model/pro_product_info.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'revenue_cat_service.g.dart';

@riverpod
Future<List<ProProductInfo>?> purchasableProducts(Ref ref) async {
  final offerings = await Purchases.getOfferings();
  final currentOffering = offerings.current;

  if (currentOffering == null) {
    return null;
  }

  final availablePackages = currentOffering.availablePackages;
  return availablePackages
      .map(
        (package) => ProProductInfo(
          productId: package.storeProduct.identifier,
          title: package.storeProduct.title,
          description: package.storeProduct.description,
          price: package.storeProduct.priceString,
          currencyCode: package.storeProduct.currencyCode,
          priceAmount: package.storeProduct.price,
        ),
      )
      .toList();
}
