import 'package:freezed_annotation/freezed_annotation.dart';
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
    await authService.signInAnonymously();

    final myHouseId = await ref.read(generateMyHouseProvider.future);
    if (myHouseId == null) {
      throw Exception('家の生成に失敗しました');
    }

    ref.read(currentHouseIdProvider.notifier).setHouseId(myHouseId);

    state = const AsyncValue.data(LoginResultValue(isSuccess: true));
  }
}
