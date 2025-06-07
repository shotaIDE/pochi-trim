import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Riverpodプロバイダーを特定の時間だけ維持するためのExtension
extension CacheForExtension on Ref {
  void cacheFor(Duration duration) {
    final link = keepAlive();
    final timer = Timer(duration, link.close);
    onDispose(timer.cancel);
  }
}
