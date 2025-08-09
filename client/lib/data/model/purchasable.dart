import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:purchases_flutter/models/package_wrapper.dart';

part 'purchasable.freezed.dart';

enum EffectivePeriod { lifetime, others }

@freezed
abstract class Purchasable with _$Purchasable {
  const factory Purchasable({
    required String productId,
    required String title,
    required EffectivePeriod effectivePeriod,
    required String description,
    required String price,
    required Package package,
  }) = _Purchasable;
}

extension PurchasableGenerator on Purchasable {
  static Purchasable fromPackage(Package package) {
    final effectivePeriod = package.packageType == PackageType.lifetime
        ? EffectivePeriod.lifetime
        : EffectivePeriod.others;

    return Purchasable(
      productId: package.storeProduct.identifier,
      title: package.storeProduct.title,
      effectivePeriod: effectivePeriod,
      description: package.storeProduct.description,
      price: package.storeProduct.priceString,
      package: package,
    );
  }
}
