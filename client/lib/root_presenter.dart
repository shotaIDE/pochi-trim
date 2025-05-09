import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/app_initial_route.dart';
import 'package:house_worker/models/app_session.dart';
import 'package:house_worker/models/preference_key.dart';
import 'package:house_worker/models/root_app_not_initialized.dart';
import 'package:house_worker/services/auth_service.dart';
import 'package:house_worker/services/preference_service.dart';
import 'package:house_worker/services/remote_config_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'root_presenter.g.dart';

@riverpod
Future<AppInitialRoute> appInitialRoute(Ref ref) async {
  // Remote Config ですでにフェッチされた値を有効化する
  await ref
      .read(updatedRemoteConfigKeysProvider.notifier)
      .ensureActivateFetchedRemoteConfigs();

  final minimumBuildNumber = ref.read(minimumBuildNumberProvider);
  // TODO(ide): 強制アップデートの実装

  final appSession = ref.watch(currentAppSessionProvider.future);
  switch (appSession) {
    case AppSessionSignedIn():
      return AppInitialRoute.home;
    case AppSessionNotSignedIn():
      return AppInitialRoute.login;
  }

  return AppInitialRoute.login;
}

@riverpod
class CurrentAppSession extends _$CurrentAppSession {
  @override
  Future<AppSession> build() async {
    // Remote Config ですでにフェッチされた値を有効化する
    await ref
        .read(updatedRemoteConfigKeysProvider.notifier)
        .ensureActivateFetchedRemoteConfigs();

    // `ref.watch` を使用すると、サインアウトした際に即時状態が更新され、
    // スプラッシュスクリーンを経由せずにリビルドされることにより、
    // MaterialApp のルートが置換されず、ログイン画面に遷移しない問題があるため、
    // `ref.read` を使用している。
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

    // スプラッシュスクリーン（ `Container` ）が表示され、ルートが置換されるまで少し待つ
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
