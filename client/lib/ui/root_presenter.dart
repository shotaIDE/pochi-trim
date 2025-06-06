import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pochi_trim/data/model/app_session.dart';
import 'package:pochi_trim/data/model/preference_key.dart';
import 'package:pochi_trim/data/model/root_app_not_initialized.dart';
import 'package:pochi_trim/data/service/app_info_service.dart';
import 'package:pochi_trim/data/service/auth_service.dart';
import 'package:pochi_trim/data/service/in_app_purchase_service.dart';
import 'package:pochi_trim/data/service/preference_service.dart';
import 'package:pochi_trim/data/service/remote_config_service.dart';
import 'package:pochi_trim/ui/app_initial_route.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'root_presenter.g.dart';

@riverpod
Future<AppInitialRoute> appInitialRoute(Ref ref) async {
  final minimumBuildNumber = ref.watch(minimumBuildNumberProvider);
  final appSessionFuture = ref.watch(currentAppSessionProvider.future);

  // Remote Config ですでにフェッチされた値を有効化する
  await ref
      .read(updatedRemoteConfigKeysProvider.notifier)
      .ensureActivateFetchedRemoteConfigs();

  if (minimumBuildNumber != null) {
    final currentAppVersion = await ref.watch(currentAppVersionProvider.future);
    final currentBuildNumber = currentAppVersion.buildNumber;
    if (currentBuildNumber < minimumBuildNumber) {
      return AppInitialRoute.updateApp;
    }
  }

  final appSession = await appSessionFuture;
  switch (appSession) {
    case AppSessionSignedIn():
      return AppInitialRoute.home;
    case AppSessionNotSignedIn():
      return AppInitialRoute.login;
  }
}

@riverpod
class CurrentAppSession extends _$CurrentAppSession {
  @override
  Future<AppSession> build() async {
    final isSignedIn = await ref.watch(isSignedInProvider.future);
    if (!isSignedIn) {
      return AppSession.notSignedIn();
    }

    final preferenceService = ref.read(preferenceServiceProvider);

    final houseId =
        await preferenceService.getString(PreferenceKey.currentHouseId) ??
        // TODO(ide): 開発用。本番リリース時には削除する
        'default-house-id';

    final isPro = await ref.read(isProUserProvider.future);

    return AppSession.signedIn(currentHouseId: houseId, isPro: isPro);
  }

  Future<void> signIn({required String userId, required String houseId}) async {
    final isPro = await ref.read(isProUserProvider.future);

    state = AsyncValue.data(
      AppSession.signedIn(currentHouseId: houseId, isPro: isPro),
    );
  }

  Future<void> signOut() async {
    state = AsyncValue.data(AppSession.notSignedIn());
  }

  Future<void> upgradeToPro() async {
    final currentAppSession = state.valueOrNull;

    if (currentAppSession case AppSessionSignedIn()) {
      final newState = currentAppSession.copyWith(isPro: true);
      state = AsyncValue.data(newState);
    }
  }
}

@riverpod
AppSession unwrappedCurrentAppSession(Ref ref) {
  final appSessionAsync = ref.watch(currentAppSessionProvider);
  final appSession = appSessionAsync.whenOrNull(
    data: (appSession) => appSession,
  );
  if (appSession == null) {
    throw RootAppNotInitializedError();
  }

  return appSession;
}
