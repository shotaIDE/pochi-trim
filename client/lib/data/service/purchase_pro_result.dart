import 'package:pochi_trim/ui/feature/pro/pro_purchase_presenter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'purchase_pro_result.g.dart';

@riverpod
class PurchaseProResult extends _$PurchaseProResult {
  @override
  Future<bool?> build() async {
    return null;
  }

  @Deprecated('Use ProPurchasePresenter instead')
  Future<bool> purchasePro() async {
    // 新しい実装を使用することを推奨
    final presenter = ref.read(proPurchasePresenterProvider.notifier);
    await presenter.purchasePro();

    final state = ref.read(proPurchasePresenterProvider);
    return state is PurchaseStateSuccess;
  }
}
