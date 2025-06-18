import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pochi_trim/data/model/app_session.dart';
import 'package:pochi_trim/data/model/preference_key.dart';
import 'package:pochi_trim/data/model/root_app_not_initialized.dart';
import 'package:pochi_trim/data/service/app_info_service.dart';
import 'package:pochi_trim/data/service/auth_service.dart';
import 'package:pochi_trim/data/service/error_report_service.dart';
import 'package:pochi_trim/data/service/preference_service.dart';
import 'package:pochi_trim/data/service/remote_config_service.dart';
import 'package:pochi_trim/ui/app_initial_route.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'root_presenter.g.dart';

@riverpod
Future<String?> updatedUserId(Ref ref) async {
  // currentUserProfileプロバイダーを監視し、ユーザーIDの設定/クリアを自動的に行う
  final userProfileAsync = ref.watch(currentUserProfileProvider);

  return await userProfileAsync.maybeWhen(
    data: (userProfile) async {
      final errorReportService = ref.read(errorReportServiceProvider);

      if (userProfile == null) {
        // ユーザーがサインアウトしている場合、CrashlyticsのユーザーIDをクリア
        await errorReportService.clearUserId();
        return null;
      }

      // ユーザーがサインインしている場合、CrashlyticsにユーザーIDを設定
      await errorReportService.setUserId(userProfile.id);
      return userProfile.id;
    },
    orElse: () {
      return null;

      // ローディング中やエラー時は何もしない
    },
  );
}

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

    final houseId = await preferenceService.getString(
      PreferenceKey.currentHouseId,
    );

    // TODO(ide): houseId が null の場合の処理を追加する
    return AppSession.signedIn(currentHouseId: houseId!);
  }

  Future<void> signIn({required String userId, required String houseId}) async {
    state = AsyncValue.data(AppSession.signedIn(currentHouseId: houseId));
  }

  Future<void> signOut() async {
    state = AsyncValue.data(AppSession.notSignedIn());
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
