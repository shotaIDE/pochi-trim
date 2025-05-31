import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:purchases_flutter/models/package_wrapper.dart';

part 'purchasable.freezed.dart';

@freezed
class ProProductInfo with _$ProProductInfo {
  const factory ProProductInfo({
    required String productId,
    required String title,
    required String description,
    required String price,
    required Package package,
  }) = _ProProductInfo;
}
