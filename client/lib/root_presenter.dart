import 'package:house_worker/models/preference_key.dart';
import 'package:house_worker/root_app_session.dart';
import 'package:house_worker/services/auth_service.dart';
import 'package:house_worker/services/preference_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'root_presenter.g.dart';

@riverpod
class RootAppInitialized extends _$RootAppInitialized {
  @override
  AppSession build() {
    return AppSession.notSignedIn();
  }

  Future<void> initialize() async {
    final userId = ref.watch(authServiceProvider).currentUser?.uid;
    if (userId == null) {
      return;
    }

    final preferenceService = ref.read(preferenceServiceProvider);

    final houseId =
        await preferenceService.getString(PreferenceKey.currentHouseId) ??
        // TODO(ide): 開発用。本番リリース時には削除する
        'default-house-id';

    // Pro版の状態を取得
    final isPremium =
        await preferenceService.getBool(PreferenceKey.isPremium) ?? false;

    state = AppSession.signedIn(
      userId: userId,
      currentHouseId: houseId,
      isPremium: isPremium,
    );
  }

  Future<void> signIn({required String userId, required String houseId}) async {
    final preferenceService = ref.read(preferenceServiceProvider);
    final isPremium =
        await preferenceService.getBool(PreferenceKey.isPremium) ?? false;

    state = AppSession.signedIn(
      userId: userId,
      currentHouseId: houseId,
      isPremium: isPremium,
    );
  }

  Future<void> signOut() async {
    state = AppSession.notSignedIn();
  }

  // Pro版にアップグレードするメソッド
  Future<void> upgradeToPro() async {
    if (state is AppSessionSignedIn) {
      final currentState = state as AppSessionSignedIn;

      // Preferenceに保存
      final preferenceService = ref.read(preferenceServiceProvider);
      await preferenceService.setBool(PreferenceKey.isPremium, value: true);

      // 状態を更新
      state = currentState.copyWith(isPremium: true);
    }
  }
}
