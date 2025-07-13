import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pochi_trim/data/model/app_session.dart';
import 'package:pochi_trim/data/model/preference_key.dart';
import 'package:pochi_trim/data/repository/house_repository.dart';
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

/// アプリの初期ルート
///
/// アプリの起動時に表示される画面を決定するものであるため、
/// 依存関係の変更に伴った再計算はしない。
/// そのため、`watch` ではなく `read` を使用している。
@riverpod
Future<AppInitialRoute> appInitialRoute(Ref ref) async {
  // Remote Config ですでにフェッチされた値を有効化する
  await ref
      .read(updatedRemoteConfigKeysProvider.notifier)
      .ensureActivateFetchedRemoteConfigs();

  final minimumBuildNumber = ref.read(minimumBuildNumberProvider);
  if (minimumBuildNumber != null) {
    final currentAppVersion = await ref.read(currentAppVersionProvider.future);
    final currentBuildNumber = currentAppVersion.buildNumber;
    if (currentBuildNumber < minimumBuildNumber) {
      return AppInitialRoute.updateApp;
    }
  }

  final isSignedIn = await ref.read(isSignedInProvider.future);
  if (!isSignedIn) {
    return AppInitialRoute.login;
  }

  final houseId = await ref.read(houseIdProvider.future);
  if (houseId == null) {
    // 現在のハウスIDが設定されていない場合は、サインアウト状態にする
    return AppInitialRoute.login;
  }

  return AppInitialRoute.home;
}

@Deprecated('Don\'t use this provider.')
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
    if (houseId == null) {
      // 現在の家が設定されていない場合は、サインアウト状態にする
      return AppSession.notSignedIn();
    }

    return AppSession.signedIn(currentHouseId: houseId);
  }

  Future<void> signIn({required String userId, required String houseId}) async {
    state = AsyncValue.data(AppSession.signedIn(currentHouseId: houseId));
  }

  Future<void> signOut() async {
    state = AsyncValue.data(AppSession.notSignedIn());
  }
}
