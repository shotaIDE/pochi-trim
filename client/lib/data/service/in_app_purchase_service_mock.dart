import 'dart:async';

import 'package:pochi_trim/data/service/in_app_purchase_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

class IsProUserMock extends IsProUser {
  @override
  Stream<bool> build() async* {
    yield true;
  }

  @override
  void setProUser({required bool isPro}) {
    state = AsyncValue.data(isPro);
  }
}
