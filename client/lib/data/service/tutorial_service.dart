import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pochi_trim/data/model/preference_key.dart';
import 'package:pochi_trim/data/service/preference_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

part 'tutorial_service.g.dart';

@riverpod
TutorialService tutorialService(Ref ref) {
  return TutorialService(ref);
}

class TutorialService {
  TutorialService(this.ref);

  final Ref ref;

  /// 初回家事登録チュートリアルを表示
  Future<void> showFirstHouseWorkTutorial({
    required BuildContext context,
    required GlobalKey houseWorkTileKey,
    required GlobalKey quickRegistrationBarKey,
  }) async {
    final preferenceService = ref.read(preferenceServiceProvider);

    // 既にチュートリアルを表示済みかチェック
    final hasShownTutorial = await preferenceService.getBool(
      PreferenceKey.hasShownFirstHouseWorkTutorial,
    );

    if (hasShownTutorial == true) {
      return;
    }

    final targets = <TargetFocus>[];

    // 家事タイルのハイライト
    targets.add(
      TargetFocus(
        identify: 'houseWorkTile',
        keyTarget: houseWorkTileKey,
        alignSkip: Alignment.bottomRight,
        enableOverlayTab: true,
        contents: [
          TargetContent(
            builder: (context, controller) => Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '家事をタップして記録',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '家事タイルをタップすると、家事ログを簡単に記録できます。',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    // クイック登録バーのハイライト
    targets.add(
      TargetFocus(
        identify: 'quickRegistrationBar',
        keyTarget: quickRegistrationBarKey,
        alignSkip: Alignment.topRight,
        enableOverlayTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) => Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'クイック登録バー',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'よく使う家事は、下のクイック登録バーからも記録できます。',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => controller.next(),
                        child: const Text('完了'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    final tutorialCoachMark = TutorialCoachMark(
      targets: targets,
      colorShadow: Theme.of(context).colorScheme.primary,
      onFinish: () async {
        // チュートリアル完了をPreferencesに保存
        await preferenceService.setBool(
          PreferenceKey.hasShownFirstHouseWorkTutorial,
          value: true,
        );
      },
      onSkip: () {
        // スキップした場合も完了として扱う
        preferenceService.setBool(
          PreferenceKey.hasShownFirstHouseWorkTutorial,
          value: true,
        );
        return true;
      },
    );

    // チュートリアル開始
    if (context.mounted) {
      tutorialCoachMark.show(context: context);
    }
  }

  /// チュートリアル状態をリセット（開発・テスト用）
  Future<void> resetTutorialState() async {
    final preferenceService = ref.read(preferenceServiceProvider);
    await preferenceService.setBool(
      PreferenceKey.hasShownFirstHouseWorkTutorial,
      value: false,
    );
  }
}
