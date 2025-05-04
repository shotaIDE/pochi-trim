import 'package:house_worker/exceptions/max_house_work_limit_exceeded_exception.dart';
import 'package:house_worker/models/house_work.dart';
import 'package:house_worker/repositories/house_work_repository.dart';
import 'package:house_worker/root_app_session.dart';
import 'package:house_worker/root_presenter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'add_house_work_presenter.g.dart';

@riverpod
class AddHouseWorkPresenter extends _$AddHouseWorkPresenter {
  @override
  FutureOr<void> build() {
    // 初期化処理
  }

  /// 家事を保存する
  ///
  /// フリー版ユーザーの場合、家事の登録数が10件以上の場合は
  /// [MaxHouseWorkLimitExceededException]をスローする
  Future<String> saveHouseWork(HouseWork houseWork) async {
    final appSession = ref.read(rootAppInitializedProvider);
    final bool isPremium;
    switch (appSession) {
      case AppSessionSignedIn():
        isPremium = appSession.isPremium;
      case AppSessionNotSignedIn():
        isPremium = false;
      case AppSessionLoading():
        isPremium = false;
    }

    if (!isPremium) {
      // Pro版でない場合、家事の数を確認
      final houseWorks =
          await ref.read(houseWorkRepositoryProvider).getAllOnce();
      if (houseWorks.length >= 10) {
        throw MaxHouseWorkLimitExceededException();
      }
    }

    // 家事を保存
    return ref.read(houseWorkRepositoryProvider).save(houseWork);
  }
}
