# 商用リリースアプリのデバッグ機能表示問題解消設計書

## 1. 概要

商用リリースアプリにおいて、以下のデバッグ機能が表示されている問題を解消するための設計を行う：

- 設定画面にデバッグ画面への動線が表示されている
- 右上にバナーが表示されている

## 2. 設計方針

### 2.1 基本方針

- 本番環境（`Flavor.prod`）のリリースモードでは、デバッグ機能を非表示にする
- 開発環境（`Flavor.dev`）とエミュレータ環境（`Flavor.emulator`）、および本番環境のデバッグモードとプロファイルモードでは、デバッグ機能を引き続き表示する
- 既存のコード構造を尊重し、変更を最小限に抑える

### 2.2 実装方針

1. デバッグ機能の表示制御のための変数を定義する
2. 設定画面のデバッグセクションと動線の表示を制御する
3. アプリのバナー表示を制御する

## 3. 詳細設計

### 3.1 デバッグ機能表示制御変数の定義

`client/lib/data/definition/app_feature.dart` に、デバッグ機能を表示するかどうかを制御する変数を追加する。

```dart
// デバッグ機能を表示するかどうか
// 本番環境のリリースモードでは非表示にする
final bool showDebugFeatures = !(flavor == Flavor.prod && kReleaseMode);
```

### 3.2 設定画面のデバッグセクションと動線の表示制御

`client/lib/ui/feature/settings/settings_screen.dart` の `build` メソッドを修正し、`showDebugFeatures` が `true` の場合のみデバッグセクションとデバッグ画面への動線を表示するようにする。

```dart
@override
Widget build(BuildContext context) {
  final userProfileAsync = ref.watch(currentUserProfileProvider);

  return Scaffold(
    appBar: AppBar(title: const Text('設定')),
    body: userProfileAsync.when(
      data: (userProfile) {
        if (userProfile == null) {
          return const Center(child: Text('ユーザー情報が取得できませんでした'));
        }

        final settingsItems = <Widget>[
          const SectionHeader(title: 'ユーザー情報'),
          _buildUserInfoTile(context, userProfile, ref),
          const Divider(),
          const SectionHeader(title: 'アプリについて'),
          const _PlanInfoPanel(),
          const _ReviewAppTile(),
          _buildShareAppTile(context),
          _buildTermsOfServiceTile(context),
          _buildPrivacyPolicyTile(context),
          _buildLicenseTile(context),
          // デバッグ機能を表示するかどうかを制御
          if (showDebugFeatures) ...[
            const SectionHeader(title: 'デバッグ'),
            _buildDebugTile(context),
          ],
          const _AppVersionTile(),
          const Divider(),
          const SectionHeader(title: 'アカウント管理'),
          _buildLogoutTile(context, ref),
          _buildDeleteAccountTile(context, ref, userProfile),
        ];

        return ListView(children: settingsItems);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('エラーが発生しました: $error')),
    ),
  );
}
```

### 3.3 アプリのバナー表示制御

`client/lib/data/definition/app_feature.dart` の `showCustomAppBanner` と `showAppDebugBanner` の定義を修正し、本番環境のリリースモードではバナーを表示しないようにする。

```dart
// カスタムアプリバナーを表示するかどうか
// 本番環境のリリースモードでは非表示にする
final bool showCustomAppBanner =
    (flavor == Flavor.prod && !kReleaseMode) || flavor != Flavor.prod;

// デバッグバナーを表示するかどうか
final bool showAppDebugBanner = !showCustomAppBanner && showDebugFeatures;
```

`client/lib/ui/root_app.dart` の `_wrapByAppBanner` メソッドは、`showCustomAppBanner` の値に基づいて動作するため、変更は不要。

## 4. 実装計画

### 4.1 変更対象ファイル

1. `client/lib/data/definition/app_feature.dart`

   - デバッグ機能表示制御変数 `showDebugFeatures` の追加
   - `showCustomAppBanner` と `showAppDebugBanner` の定義修正

2. `client/lib/ui/feature/settings/settings_screen.dart`
   - `build` メソッドの修正（デバッグセクションと動線の条件付き表示）

### 4.2 実装手順

1. `app_feature.dart` に `showDebugFeatures` 変数を追加する
2. `app_feature.dart` の `showCustomAppBanner` と `showAppDebugBanner` の定義を修正する
3. `settings_screen.dart` の `build` メソッドを修正する
4. 各環境でのテストを実施する

## 5. テスト計画

### 5.1 単体テスト

1. `showDebugFeatures` の値が環境とビルドモードによって正しく設定されることを確認するテスト

   - 本番環境のリリースモードでは `false`
   - その他の環境・モードでは `true`

2. `showCustomAppBanner` と `showAppDebugBanner` の値が環境とビルドモードによって正しく設定されることを確認するテスト
   - 本番環境のリリースモードでは両方とも `false`
   - その他の環境・モードでは適切な値

### 5.2 結合テスト

1. 設定画面のデバッグセクションと動線の表示制御が正しく機能することを確認するテスト

   - 本番環境のリリースモードでは非表示
   - その他の環境・モードでは表示

2. アプリのバナー表示制御が正しく機能することを確認するテスト
   - 本番環境のリリースモードでは非表示
   - その他の環境・モードでは表示

### 5.3 手動テスト

1. 各環境（本番、開発、エミュレータ）でアプリを起動し、設定画面のデバッグセクションと動線、およびバナーの表示状態を確認する

   - 本番環境のリリースモードでは非表示
   - その他の環境・モードでは表示

2. 各環境で設定画面の他の機能が正常に動作することを確認する
   - デバッグセクションの表示/非表示によって他の機能に影響がないこと

## 6. 影響範囲と考慮事項

### 6.1 影響範囲

- `client/lib/data/definition/app_feature.dart`
- `client/lib/ui/feature/settings/settings_screen.dart`

### 6.2 考慮事項

- デバッグ機能自体は削除せず、表示制御のみを変更するため、開発時の利便性は維持される
- 本番環境のデバッグモードとプロファイルモードでは引き続きデバッグ機能を表示するため、テスト時の確認は可能
- 変更は UI の表示制御のみであり、機能的な変更はないため、リグレッションリスクは低い

## 7. 結論

この設計により、商用リリースアプリにおけるデバッグ機能の表示問題を解消することができる。環境とビルドモードに基づいて表示を制御することで、開発時の利便性を維持しながら、エンドユーザーに対しては不要な機能を非表示にすることができる。

実装は既存のコード構造を尊重し、変更を最小限に抑えることで、保守性を維持する。また、テストを通じて各環境での動作を確認することで、品質を担保する。
