import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'system_service.g.dart';

@riverpod
SystemService systemService(Ref ref) {
  return SystemService();
}

/// システムの情報を提供するクラス
///
/// テスト時にモックできるようにするため、プロバイダーとして定義している。
class SystemService {
  /// 現在の日時を取得する
  DateTime getCurrentDateTime() {
    return DateTime.now();
  }
}
