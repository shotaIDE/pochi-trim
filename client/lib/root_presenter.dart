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

    state = AppSession.signedIn(userId: userId, currentHouseId: houseId);
  }

  Future<void> signIn({required String userId, required String houseId}) async {
    state = AppSession.signedIn(userId: userId, currentHouseId: houseId);
  }
}
