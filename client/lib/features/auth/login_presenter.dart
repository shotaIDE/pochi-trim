import 'package:house_worker/models/generate_my_house_exception.dart';
import 'package:house_worker/models/sign_in_result.dart';
import 'package:house_worker/root_presenter.dart';
import 'package:house_worker/services/auth_service.dart';
import 'package:house_worker/services/functions_service.dart';
import 'package:logging/logging.dart';
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
    final SignInResult result;
    try {
      result = await authService.signInWithGoogle();
    } on SignInException catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return;
    }

    switch (result) {
      case SignInSuccess(userId: final userId, isNewUser: final isNewUser):
        _logger.info(
          'Google sign-in successful. User ID = $userId, new user = $isNewUser',
        );

        final String myHouseId;
        try {
          myHouseId = await ref.read(generateMyHouseProvider.future);
        } on GenerateMyHouseException catch (e, stack) {
          state = AsyncValue.error(e, stack);
          return;
        }

        await ref
            .read(currentAppSessionProvider.notifier)
            .signIn(userId: userId, houseId: myHouseId);

      case SignInCancelled():
        _logger.info('Google sign-in cancelled.');
        return;
    }
  }

  Future<void> startWithoutAccount() async {
    state = const AsyncValue.loading();

    final authService = ref.read(authServiceProvider);
    final String userId;
    try {
      userId = await authService.signInAnonymously();
    } on SignInException catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return;
    }

    final String myHouseId;
    try {
      myHouseId = await ref.read(generateMyHouseProvider.future);
    } on GenerateMyHouseException catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return;
    }

    await ref
        .read(currentAppSessionProvider.notifier)
        .signIn(userId: userId, houseId: myHouseId);
  }
}
