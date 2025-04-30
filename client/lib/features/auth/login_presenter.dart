import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:house_worker/services/auth_service.dart';
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
    final authService = ref.watch(authServiceProvider);

    state = const AsyncValue.loading();

    await authService.signInAnonymously();

    // TODO(ide): エラーハンドリング
    state = const AsyncValue.data(LoginResultValue(isSuccess: true));
  }
}
