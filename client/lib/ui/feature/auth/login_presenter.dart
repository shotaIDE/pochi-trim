import 'package:logging/logging.dart';
import 'package:pochi_trim/data/model/generate_my_house_exception.dart';
import 'package:pochi_trim/data/model/preference_key.dart';
import 'package:pochi_trim/data/model/sign_in_result.dart';
import 'package:pochi_trim/data/repository/house_repository.dart';
import 'package:pochi_trim/data/service/auth_service.dart';
import 'package:pochi_trim/data/service/functions_service.dart';
import 'package:pochi_trim/data/service/preference_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'login_presenter.g.dart';

/// ログイン処理の状態
enum LoginStatus {
  /// 何も実行していない
  none,

  /// Googleアカウントでログイン中
  signingInWithGoogle,

  /// Appleアカウントでログイン中
  signingInWithApple,

  /// 匿名アカウントでログイン中
  signingInAnonymously,
}

/// 現在のログイン処理状態を管理する
@riverpod
class CurrentLoginStatus extends _$CurrentLoginStatus {
  final _logger = Logger('CurrentLoginStatus');

  @override
  LoginStatus build() => LoginStatus.none;

  /// Googleアカウントでサインインする
  ///
  /// Throws:
  /// - [SignInWithGoogleException]: Google認証でエラーが発生した場合
  /// - [GenerateMyHouseException]: 家ID生成APIでエラーが発生した場合
  Future<void> startWithGoogle() async {
    state = LoginStatus.signingInWithGoogle;
    final authService = ref.read(authServiceProvider);

    try {
      final result = await authService.signInWithGoogle();
      final userId = result.userId;
      _logger.info(
        'Google sign-in successful. '
        'User ID = $userId, new user = ${result.isNewUser}',
      );
      await _completeSignIn(userId: userId);
    } finally {
      state = LoginStatus.none;
    }
  }

  /// Appleアカウントでサインインする
  ///
  /// Throws:
  /// - [SignInWithAppleException]: Apple認証でエラーが発生した場合
  /// - [GenerateMyHouseException]: 家ID生成APIでエラーが発生した場合
  Future<void> startWithApple() async {
    state = LoginStatus.signingInWithApple;

    final authService = ref.read(authServiceProvider);
    try {
      final result = await authService.signInWithApple();

      final userId = result.userId;
      _logger.info(
        'Apple sign-in successful. '
        'User ID = $userId, new user = ${result.isNewUser}',
      );

      await _completeSignIn(userId: userId);
    } finally {
      state = LoginStatus.none;
    }
  }

  /// 匿名アカウントでサインインする
  ///
  /// Throws:
  /// - [GenerateMyHouseException]: 家ID生成APIでエラーが発生した場合
  Future<void> startWithoutAccount() async {
    state = LoginStatus.signingInAnonymously;

    final authService = ref.read(authServiceProvider);
    try {
      final userId = await authService.signInAnonymously();

      await _completeSignIn(userId: userId);
    } finally {
      state = LoginStatus.none;
    }
  }

  Future<void> _completeSignIn({required String userId}) async {
    final result = await ref.read(generateMyHouseProvider.future);

    await ref.read(currentHouseIdProvider.notifier).setId(result.houseId);

    // チュートリアルの表示有無が一度も設定されていない場合、設定する
    // 新しい家が作成された場合のみ、チュートリアルを表示する
    final preferenceService = ref.read(preferenceServiceProvider);
    final shouldShowHowToRegisterWorkLogsTutorial = await preferenceService
        .getBool(
          PreferenceKey.shouldShowHowToRegisterWorkLogsTutorial,
        );
    if (shouldShowHowToRegisterWorkLogsTutorial == null) {
      await preferenceService.setBool(
        PreferenceKey.shouldShowHowToRegisterWorkLogsTutorial,
        value: result.isNewHouse,
      );
    }

    final shouldShowHowToCheckWorkLogsAndAnalysisTutorial =
        await preferenceService.getBool(
          PreferenceKey.shouldShowHowToCheckWorkLogsAndAnalysisTutorial,
        );
    if (shouldShowHowToCheckWorkLogsAndAnalysisTutorial == null) {
      await preferenceService.setBool(
        PreferenceKey.shouldShowHowToCheckWorkLogsAndAnalysisTutorial,
        value: result.isNewHouse,
      );
    }

    await ref.read(currentHouseIdProvider.notifier).setId(result.houseId);
  }
}
