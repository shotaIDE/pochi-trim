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
    return AppSession.loading();
  }

  Future<void> initialize() async {
    final userProfile = await ref.watch(currentUserProfileProvider.future);
    if (userProfile == null) {
      state = AppSession.notSignedIn();

      return;
    }

    final preferenceService = ref.read(preferenceServiceProvider);

    final houseId =
        await preferenceService.getString(PreferenceKey.currentHouseId) ??
        // TODO(ide): 開発用。本番リリース時には削除する
        'default-house-id';

    // TODO(ide): RevenueCatから取得する開発用。本番リリース時には削除する
    const isPro = false;

    state = AppSession.signedIn(
      userId: userProfile.id,
      currentHouseId: houseId,
      isPro: isPro,
    );
  }

  Future<void> signIn({required String userId, required String houseId}) async {
    // TODO(ide): RevenueCatから取得する開発用。本番リリース時には削除する
    const isPro = false;

    state = AppSession.signedIn(
      userId: userId,
      currentHouseId: houseId,
      isPro: isPro,
    );
  }

  Future<void> signOut() async {
    state = AppSession.loading();

    await Future<void>.delayed(const Duration(seconds: 1));

    state = AppSession.notSignedIn();
  }

  Future<void> upgradeToPro() async {
    if (state is! AppSessionSignedIn) {
      return;
    }

    final currentState = state as AppSessionSignedIn;

    state = currentState.copyWith(isPro: true);
  }
}
