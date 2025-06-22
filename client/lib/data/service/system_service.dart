import 'package:flutter/services.dart';
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

  /// ユーザーアクションが受け取られたときの触覚フィードバックを実行する
  Future<void> doHapticFeedbackActionReceived() async {
    await HapticFeedback.mediumImpact();
  }

  /// ユーザーアクションが拒否されたときの触覚フィードバックを実行する
  Future<void> doHapticFeedbackActionRejected() async {
    // リジェクトされた感を伝えるため、断続的なパターンで振動させる
    // パターン: 短い振動 → 休止 → 短い振動 → 休止 → 長い振動
    // `vibration` ライブラリが以下のようなパターンを表現するために適切だが、
    // ライブラリが SPM 対応しておらずメンテナンス性の懸念があるため利用していない。
    await HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.heavyImpact();
  }
}
