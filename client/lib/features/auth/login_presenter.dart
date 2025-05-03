import 'package:house_worker/models/generate_my_house_exception.dart';
import 'package:house_worker/models/sign_in_result.dart';
import 'package:house_worker/root_presenter.dart';
import 'package:house_worker/services/auth_service.dart';
import 'package:house_worker/services/functions_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'login_presenter.g.dart';

@riverpod
class LoginButtonTappedResult extends _$LoginButtonTappedResult {
  @override
  Future<void> build() async {
    return;
  }

  Future<void> onLoginTapped() async {
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
        .read(rootAppInitializedProvider.notifier)
        .signIn(userId: userId, houseId: myHouseId);
  }
}
