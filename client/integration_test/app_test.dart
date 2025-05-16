import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pochi_trim/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('家事登録と家事ログのクイック登録テスト', () {
    testWidgets('家事を登録した後、家事ログをクイック登録ボタンから登録できる', (tester) async {
      // アプリを起動
      app.main();
      await tester.pumpAndSettle();

      // ログイン状態を確認（必要に応じてログイン処理を追加）
      // このテストでは、すでにログインしていることを前提としています

      // 家事追加ボタンをタップ
      await tester.tap(find.byTooltip('家事を追加する'));
      await tester.pumpAndSettle();

      // 家事名を入力
      final testHouseWorkTitle =
          '掃除テスト${DateTime.now().millisecondsSinceEpoch}';
      await tester.enterText(
        find.widgetWithText(TextFormField, '家事名'),
        testHouseWorkTitle,
      );
      await tester.pumpAndSettle();

      // 登録ボタンをタップ
      await tester.tap(find.text('家事を登録する'));
      await tester.pumpAndSettle();

      // スナックバーが表示されることを確認
      expect(find.text('家事を登録しました'), findsOneWidget);

      // ホーム画面に戻ったことを確認
      expect(find.text('記録'), findsOneWidget);

      // 登録した家事が表示されていることを確認
      expect(find.text(testHouseWorkTitle), findsOneWidget);

      // クイック登録ボタンを探す（画面下部のクイック登録バーにある家事ボタン）
      final quickRegisterButton = find.text(testHouseWorkTitle).last;
      expect(quickRegisterButton, findsOneWidget);

      // クイック登録ボタンをタップ
      await tester.tap(quickRegisterButton);
      await tester.pumpAndSettle();

      // スナックバーが表示されることを確認
      expect(find.text('家事ログを記録しました'), findsOneWidget);

      // ログタブに切り替え
      await tester.tap(find.text('ログ'));
      await tester.pumpAndSettle();

      // 登録した家事ログが表示されていることを確認
      expect(find.text(testHouseWorkTitle), findsOneWidget);
    });
  });
}
