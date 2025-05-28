import 'package:freezed_annotation/freezed_annotation.dart';

part 'pro_product_info.freezed.dart';

@freezed
class ProProductInfo with _$ProProductInfo {
  const factory ProProductInfo({
    required String productId,
    required String title,
    required String description,
    required String price,
    required String currencyCode,
    required double priceAmount,
  }) = _ProProductInfo;
}
