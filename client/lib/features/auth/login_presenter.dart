import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:house_worker/models/sign_in_result.dart';
import 'package:house_worker/services/auth_service.dart';
import 'package:house_worker/services/functions_service.dart';
import 'package:house_worker/services/house_id_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'login_presenter.freezed.dart';
part 'login_presenter.g.dart';

@freezed
abstract class LoginResultValue with _$LoginResultValue {
  const factory LoginResultValue({required bool isSuccess}) = _LoginResultValue;
}

@riverpod
class LoginButtonTappedResult extends _$LoginButtonTappedResult {
  @override
  Future<LoginResultValue?> build() async {
    return null;
  }

  Future<void> onLoginTapped() async {
    state = const AsyncValue.loading();

    final authService = ref.read(authServiceProvider);
    try {
      await authService.signInAnonymously();
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

    ref.read(currentHouseIdProvider.notifier).setHouseId(myHouseId);
  }
}
