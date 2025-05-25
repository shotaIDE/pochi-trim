import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pochi_trim/data/model/preference_key.dart';
import 'package:pochi_trim/data/service/in_app_purchase_service.dart';
import 'package:pochi_trim/data/service/preference_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

class IsProUserMock extends IsProUser {
  @override
  Stream<bool> build() async* {
    final preferenceService = ref.read(preferenceServiceProvider);
    final savedValue = await preferenceService.getBool(
      PreferenceKey.isProUserForDebug,
    );

    final initialValue = savedValue ?? true;

    yield initialValue;

    final controller = StreamController<bool>();

    ref.onDispose(controller.close);

    yield* controller.stream;
  }

  @override
  Future<void> setProUser({required bool isPro}) async {
    state = AsyncValue.data(isPro);

    final preferenceService = ref.read(preferenceServiceProvider);
    await preferenceService.setBool(
      PreferenceKey.isProUserForDebug,
      value: isPro,
    );
  }
}
