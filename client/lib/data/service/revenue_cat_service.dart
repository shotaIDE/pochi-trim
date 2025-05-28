import 'package:pochi_trim/data/model/pro_product_info.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'revenue_cat_service.g.dart';

@riverpod
class RevenueCatService extends _$RevenueCatService {
  @override
  Future<ProProductInfo?> build() async {
    try {
      final offerings = await Purchases.getOfferings();
      final currentOffering = offerings.current;

      if (currentOffering == null) {
        return null;
      }

      // 'pro'パッケージを探す
      final proPackage = currentOffering.getPackage('pro');
      if (proPackage == null) {
        // パッケージが見つからない場合、利用可能なパッケージから最初のものを使用
        final availablePackages = currentOffering.availablePackages;
        if (availablePackages.isEmpty) {
          return null;
        }

        final firstPackage = availablePackages.first;
        return ProProductInfo(
          productId: firstPackage.storeProduct.identifier,
          title: firstPackage.storeProduct.title,
          description: firstPackage.storeProduct.description,
          price: firstPackage.storeProduct.priceString,
          currencyCode: firstPackage.storeProduct.currencyCode,
          priceAmount: firstPackage.storeProduct.price,
        );
      }

      return ProProductInfo(
        productId: proPackage.storeProduct.identifier,
        title: proPackage.storeProduct.title,
        description: proPackage.storeProduct.description,
        price: proPackage.storeProduct.priceString,
        currencyCode: proPackage.storeProduct.currencyCode,
        priceAmount: proPackage.storeProduct.price,
      );
    } on Exception catch (e) {
      // エラーログ出力
      // TODO(ide): 本番環境では適切なログシステムを使用する
      // ignore: avoid_print
      print('RevenueCat商品情報取得エラー: $e');
      return null;
    }
  }

  /// 商品情報を再取得する
  void refresh() {
    ref.invalidateSelf();
  }
}
