import 'package:house_worker/data/model/app_session.dart';
import 'package:house_worker/ui/root_presenter.dart';
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

    final appSession = ref.read(unwrappedCurrentAppSessionProvider);
    if (appSession is AppSessionSignedIn) {
      await ref.read(currentAppSessionProvider.notifier).upgradeToPro();
    }

    return true;
  }
}
