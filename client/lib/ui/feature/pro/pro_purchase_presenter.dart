import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pochi_trim/data/definition/app_definition.dart';
import 'package:pochi_trim/data/model/app_session.dart';
import 'package:pochi_trim/data/model/pro_product_info.dart';
import 'package:pochi_trim/data/service/revenue_cat_service.dart';
import 'package:pochi_trim/ui/root_presenter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pro_purchase_presenter.freezed.dart';
part 'pro_purchase_presenter.g.dart';

@freezed
class PurchaseState with _$PurchaseState {
  const factory PurchaseState.loading() = PurchaseStateLoading;
  const factory PurchaseState.loaded(List<ProProductInfo> productInfo) =
      PurchaseStateLoaded;
  const factory PurchaseState.purchasing() = PurchaseStatePurchasing;
  const factory PurchaseState.success() = PurchaseStateSuccess;
  const factory PurchaseState.error(String message) = PurchaseStateError;
}

@riverpod
class ProPurchasePresenter extends _$ProPurchasePresenter {
  @override
  PurchaseState build() {
    final productsAsync = ref.watch(purchasableProductsProvider);

    return productsAsync.when(
      data: (products) {
        if (products != null) {
          return PurchaseState.loaded(products);
        } else {
          return const PurchaseState.error('商品情報を取得できませんでした');
        }
      },
      loading: () => const PurchaseState.loading(),
      error: (_, _) {
        return const PurchaseState.error('商品情報の取得に失敗しました');
      },
    );
  }

  Future<void> purchasePro(ProProductInfo product) async {
    final currentState = state;
    if (currentState is! PurchaseStateLoaded) {
      return;
    }

    state = const PurchaseState.purchasing();

    try {
      final offerings = await Purchases.getOfferings();
      final currentOffering = offerings.current;

      if (currentOffering == null) {
        state = const PurchaseState.error('商品が見つかりませんでした');
        return;
      }

      final proPackage = currentOffering.getPackage(product.productId);
      if (proPackage == null) {
        state = const PurchaseState.error('購入可能な商品が見つかりませんでした');
        return;
      }

      final customerInfo = await Purchases.purchasePackage(proPackage);

      if (customerInfo.entitlements.active[revenueCatProEntitlementId] !=
          null) {
        // AppSession更新
        final appSession = ref.read(unwrappedCurrentAppSessionProvider);
        if (appSession is AppSessionSignedIn) {
          await ref.read(currentAppSessionProvider.notifier).upgradeToPro();
        }

        state = const PurchaseState.success();
      } else {
        state = const PurchaseState.error('購入処理が完了しませんでした');
      }
    } on Exception catch (e) {
      state = PurchaseState.error(_getErrorMessage(e));
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is PurchasesError) {
      final code = error.code;
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        return '購入がキャンセルされました';
      } else if (code == PurchasesErrorCode.storeProblemError) {
        return 'ストアに問題が発生しています。しばらく時間をおいて再試行してください';
      } else if (code == PurchasesErrorCode.purchaseNotAllowedError) {
        return '購入が許可されていません';
      } else if (code == PurchasesErrorCode.purchaseInvalidError) {
        return '無効な購入です';
      } else if (code ==
          PurchasesErrorCode.productNotAvailableForPurchaseError) {
        return '商品が購入できません';
      } else if (code == PurchasesErrorCode.networkError) {
        return 'ネットワークエラーが発生しました。接続を確認してください';
      } else if (code == PurchasesErrorCode.productAlreadyPurchasedError) {
        return 'この商品は既に購入済みです';
      } else {
        return '購入処理中にエラーが発生しました';
      }
    }
    return '予期しないエラーが発生しました';
  }
}
