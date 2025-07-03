import 'package:logging/logging.dart';
import 'package:pochi_trim/data/model/generate_my_house_exception.dart';
import 'package:pochi_trim/data/model/preference_key.dart';
import 'package:pochi_trim/data/model/sign_in_result.dart';
import 'package:pochi_trim/data/service/auth_service.dart';
import 'package:pochi_trim/data/service/functions_service.dart';
import 'package:pochi_trim/data/service/preference_service.dart';
import 'package:pochi_trim/ui/root_presenter.dart';
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

    // 家IDを永続化する
    final preferenceService = ref.read(preferenceServiceProvider);
    await preferenceService.setString(
      PreferenceKey.currentHouseId,
      value: result.houseId,
    );

    // 新しい家の場合はチュートリアルを表示するため、フラグを設定する
    if (result.isNewHouse) {
      await preferenceService.setBool(
        PreferenceKey.shouldShowHowToRegisterWorkLogsTutorial,
        value: true,
      );
      await preferenceService.setBool(
        PreferenceKey.shouldShowHowToCheckWorkLogsAndAnalysisTutorial,
        value: true,
      );
    }

    await ref
        .read(currentAppSessionProvider.notifier)
        .signIn(userId: userId, houseId: result.houseId);
  }
}
