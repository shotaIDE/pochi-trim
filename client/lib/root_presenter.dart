import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/models/preference_key.dart';
import 'package:house_worker/models/root_app_not_initialized.dart';
import 'package:house_worker/root_app_session.dart';
import 'package:house_worker/services/auth_service.dart';
import 'package:house_worker/services/preference_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'root_presenter.g.dart';

@riverpod
class RootAppInitialized extends _$RootAppInitialized {
  @override
  Future<AppSession> build() async {
    final userProfile = await ref.read(currentUserProfileProvider.future);
    if (userProfile == null) {
      return AppSession.notSignedIn();
    }

    final preferenceService = ref.read(preferenceServiceProvider);

    final houseId =
        await preferenceService.getString(PreferenceKey.currentHouseId) ??
        // TODO(ide): 開発用。本番リリース時には削除する
        'default-house-id';

    // TODO(ide): RevenueCatから取得する開発用。本番リリース時には削除する
    const isPro = false;

    return AppSession.signedIn(
      userId: userProfile.id,
      currentHouseId: houseId,
      isPro: isPro,
    );
  }

  Future<void> signIn({required String userId, required String houseId}) async {
    // TODO(ide): RevenueCatから取得する開発用。本番リリース時には削除する
    const isPro = false;

    state = AsyncValue.data(
      AppSession.signedIn(
        userId: userId,
        currentHouseId: houseId,
        isPro: isPro,
      ),
    );
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();

    // Wait a bit so that the splash screen appears
    // and the routes replacement runs.
    await Future<void>.delayed(const Duration(milliseconds: 10));

    state = AsyncValue.data(AppSession.notSignedIn());
  }

  Future<void> upgradeToPro() async {
    if (state is! AppSessionSignedIn) {
      return;
    }

    final currentState = state as AppSessionSignedIn;
    final newState = currentState.copyWith(isPro: true);

    state = AsyncValue.data(newState);
  }
}

@riverpod
AppSession unwrappedAppSession(Ref ref) {
  final appSessionAsync = ref.watch(rootAppInitializedProvider);
  final appSession = appSessionAsync.whenOrNull(
    data: (appSession) => appSession,
  );
  if (appSession == null) {
    throw RootAppNotInitializedError();
  }

  return appSession;
}
