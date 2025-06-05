import 'package:freezed_annotation/freezed_annotation.dart';

part 'purchase_exception.freezed.dart';

@freezed
sealed class PurchaseException with _$PurchaseException implements Exception {
  const factory PurchaseException.cancelled() = PurchaseExceptionCancelled;

  const factory PurchaseException.uncategorized() =
      PurchaseExceptionUncategorized;
}

@freezed
sealed class RestorePurchaseException
    with _$RestorePurchaseException
    implements Exception {
  const factory RestorePurchaseException.notFound() =
      RestorePurchaseExceptionNotFound;

  const factory RestorePurchaseException.uncategorized() =
      RestorePurchaseExceptionUncategorized;
}
