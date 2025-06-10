import 'package:logging/logging.dart';
import 'package:pochi_trim/data/model/preference_key.dart';
import 'package:pochi_trim/data/service/auth_service.dart';
import 'package:pochi_trim/data/service/functions_service.dart';
import 'package:pochi_trim/data/service/preference_service.dart';
import 'package:pochi_trim/ui/root_presenter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'login_presenter.g.dart';

@riverpod
class StartResult extends _$StartResult {
  final _logger = Logger('StartResult');

  @override
  Future<void> build() async {
    return;
  }

  Future<void> startWithGoogle() async {
    state = const AsyncValue.loading();

    final authService = ref.read(authServiceProvider);
    final result = await authService.signInWithGoogle();

    final userId = result.userId;
    final isNewUser = result.isNewUser;
    _logger.info(
      'Google sign-in successful. User ID = $userId, new user = $isNewUser',
    );

    final myHouseId = await ref.read(generateMyHouseProvider.future);

    // 家IDを永続化する
    final preferenceService = ref.read(preferenceServiceProvider);
    await preferenceService.setString(
      PreferenceKey.currentHouseId,
      value: myHouseId,
    );

    await ref
        .read(currentAppSessionProvider.notifier)
        .signIn(userId: userId, houseId: myHouseId);
  }

  Future<void> startWithApple() async {
    state = const AsyncValue.loading();

    final authService = ref.read(authServiceProvider);
    final result = await authService.signInWithApple();

    final userId = result.userId;
    final isNewUser = result.isNewUser;
    _logger.info(
      'Apple sign-in successful. User ID = $userId, new user = $isNewUser',
    );

    final myHouseId = await ref.read(generateMyHouseProvider.future);

    // 家IDを永続化する
    final preferenceService = ref.read(preferenceServiceProvider);
    await preferenceService.setString(
      PreferenceKey.currentHouseId,
      value: myHouseId,
    );

    await ref
        .read(currentAppSessionProvider.notifier)
        .signIn(userId: userId, houseId: myHouseId);
  }

  Future<void> startWithoutAccount() async {
    state = const AsyncValue.loading();

    final authService = ref.read(authServiceProvider);
    final userId = await authService.signInAnonymously();

    final myHouseId = await ref.read(generateMyHouseProvider.future);

    // 家IDを永続化する
    final preferenceService = ref.read(preferenceServiceProvider);
    await preferenceService.setString(
      PreferenceKey.currentHouseId,
      value: myHouseId,
    );

    await ref
        .read(currentAppSessionProvider.notifier)
        .signIn(userId: userId, houseId: myHouseId);
  }
}
