import 'package:house_worker/root_app_session.dart';
import 'package:house_worker/root_presenter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'purchase_pro_result.g.dart';

@riverpod
class PurchaseProResult extends _$PurchaseProResult {
  @override
  Future<bool?> build() async {
    return null;
  }

  Future<bool> purchasePro() async {
    // TODO(ide): RevenueCatを使用して課金処理を実行

    final appSession = ref.read(rootAppInitializedProvider);
    if (appSession is AppSessionSignedIn) {
      await ref.read(rootAppInitializedProvider.notifier).upgradeToPro();
    }

    return true;
  }
}
