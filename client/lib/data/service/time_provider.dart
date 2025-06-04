import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'time_provider.g.dart';

@riverpod
TimeProvider timeProvider(Ref ref) {
  return TimeProvider();
}

/// 現在時刻を提供するクラス（テスト時にモックできるようにするため）
class TimeProvider {
  /// 現在の日時を取得する
  DateTime now() {
    return DateTime.now();
  }
}