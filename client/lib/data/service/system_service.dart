import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vibration/vibration.dart';

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
    // vibrationが利用可能かチェック
    final hasVibrator = await Vibration.hasVibrator();
    if (!hasVibrator) {
      // vibrationが利用できない場合はHapticFeedbackにフォールバック
      await HapticFeedback.heavyImpact();
      return;
    }

    // リジェクトされた感を伝えるため、断続的なパターンで振動させる
    // パターン: 短い振動 → 休止 → 短い振動 → 休止 → 長い振動
    await Vibration.vibrate(
      pattern: [
        0, // 開始遅延なし
        200, // 短い振動
        100, // 休止
        200, // 短い振動
        100, // 休止
        400, // 長い振動（リジェクト感を強調）
      ],
    );
  }
}
