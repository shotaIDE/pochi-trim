# 設定画面からのプロ版アップグレード機能の設計ドキュメント

## 概要

設定画面からプロ版へのアップグレード機能を追加し、現在のプラン（フリー版/プロ版）を表示する機能を実装する。

## 実装計画

### 1. 設定画面でのプラン表示

#### 1.1 UI コンポーネントの追加

- 設定画面の「アプリについて」セクションに「現在のプラン」の項目を追加する
- `PlanInfoTile` という名前の `ConsumerWidget` を作成し、現在のプランに応じた表示を行う

#### 1.2 プラン情報の取得

- `isProUserProvider` を使用して現在のプラン情報を取得する
- `userProfileAsync` と同様に非同期で取得し、ローディング状態とエラー状態を適切に処理する

```dart
// 疑似コード
final isProAsync = ref.watch(isProUserProvider);

return isProAsync.when(
  data: (isPro) => _buildPlanInfoTile(context, isPro),
  loading: () => const _SkeletonPlanInfoTile(),
  error: (error, stack) => _ErrorPlanInfoTile(),
);
```

### 2. プロ版へのアップグレードボタン

#### 2.1 アップグレードボタンの表示

- フリー版ユーザーの場合のみ、「プロ版にアップグレード」ボタンを表示する
- ボタンは目立つデザインにし、「現在のプラン」表示の近くに配置する

```dart
// 疑似コード
Widget _buildUpgradeToProButton(BuildContext context) {
  return ListTile(
    leading: const Icon(Icons.upgrade),
    title: const Text('Pro版にアップグレード'),
    trailing: const _MoveScreenTrailingIcon(),
    onTap: () => Navigator.of(context).push(UpgradeToProScreen.route()),
  );
}
```

#### 2.2 条件付き表示

- `isProUserProvider` の値に基づいて、アップグレードボタンの表示/非表示を切り替える

```dart
// 疑似コード
if (!isPro) {
  children.add(_buildUpgradeToProButton(context));
}
```

### 3. 画面遷移の実装

- アップグレードボタンをタップした際に `UpgradeToProScreen` に遷移する
- 既存の `UpgradeToProScreen.route()` を使用する

```dart
// 疑似コード
onTap: () => Navigator.of(context).push(UpgradeToProScreen.route()),
```

### 4. プラン情報の更新処理

- `UpgradeToProScreen` での購入完了後、設定画面に戻った際に正しいプラン表示に更新されるようにする
- `isProUserProvider` は `Stream<bool>` を返すため、プラン情報の変更を自動的に検知して UI を更新する

### 5. エラーハンドリング

- プラン情報の取得に失敗した場合のエラー表示を実装する
- ネットワーク接続がない場合のエラー処理を実装する

```dart
// 疑似コード
Widget _ErrorPlanInfoTile() {
  return const ListTile(
    leading: Icon(Icons.error),
    title: Text('プラン情報の取得に失敗しました'),
  );
}
```

## 実装手順

1. `settings_screen.dart` に「現在のプラン」表示用のウィジェットを追加する
2. `isProUserProvider` を使用してプラン情報を取得する処理を実装する
3. フリー版ユーザーの場合のみ表示する「プロ版にアップグレード」ボタンを実装する
4. アップグレードボタンをタップした際に `UpgradeToProScreen` に遷移する処理を実装する
5. プラン情報の更新処理とエラーハンドリングを実装する
6. UI のスタイリングを調整する

## 関連するファイル

- `client/lib/ui/feature/settings/settings_screen.dart`

  - 設定画面の UI 実装
  - 「現在のプラン」表示と「プロ版にアップグレード」ボタンを追加する

- `client/lib/ui/feature/pro/upgrade_to_pro_screen.dart`

  - プロ版アップグレード画面の実装
  - 既存の実装を利用する

- `client/lib/data/service/in_app_purchase_service.dart`

  - プロ版ステータスの取得処理
  - `isProUserProvider` を使用してプラン情報を取得する

- `client/lib/ui/root_presenter.dart`
  - アプリのセッション管理
  - `CurrentAppSession` クラスの `upgradeToPro` メソッドを使用してプラン情報を更新する

## テスト計画

### 1. ユニットテスト

- `isProUserProvider` の値に応じて正しいプラン表示が行われることをテストする
- フリー版ユーザーの場合のみアップグレードボタンが表示されることをテストする

```dart
// 疑似コード
testWidgets('フリー版ユーザーの場合、アップグレードボタンが表示される', (tester) async {
  // モックの設定
  when(mockIsProUserProvider.build()).thenAnswer((_) => Stream.value(false));

  // ウィジェットのビルド
  await tester.pumpWidget(ProviderScope(
    overrides: [
      isProUserProvider.overrideWith((ref) => mockIsProUserProvider),
    ],
    child: const MaterialApp(home: SettingsScreen()),
  ));

  // アップグレードボタンが表示されていることを確認
  expect(find.text('プロ版にアップグレード'), findsOneWidget);
});

testWidgets('プロ版ユーザーの場合、アップグレードボタンが表示されない', (tester) async {
  // モックの設定
  when(mockIsProUserProvider.build()).thenAnswer((_) => Stream.value(true));

  // ウィジェットのビルド
  await tester.pumpWidget(ProviderScope(
    overrides: [
      isProUserProvider.overrideWith((ref) => mockIsProUserProvider),
    ],
    child: const MaterialApp(home: SettingsScreen()),
  ));

  // アップグレードボタンが表示されていないことを確認
  expect(find.text('プロ版にアップグレード'), findsNothing);
});
```

### 2. ウィジェットテスト

- 設定画面に「現在のプラン」表示が正しく追加されていることをテストする
- アップグレードボタンをタップした際に `UpgradeToProScreen` に遷移することをテストする

```dart
// 疑似コード
testWidgets('アップグレードボタンをタップすると、UpgradeToProScreen に遷移する', (tester) async {
  // モックの設定
  when(mockIsProUserProvider.build()).thenAnswer((_) => Stream.value(false));

  // ウィジェットのビルド
  await tester.pumpWidget(ProviderScope(
    overrides: [
      isProUserProvider.overrideWith((ref) => mockIsProUserProvider),
    ],
    child: const MaterialApp(home: SettingsScreen()),
  ));

  // アップグレードボタンをタップ
  await tester.tap(find.text('プロ版にアップグレード'));
  await tester.pumpAndSettle();

  // UpgradeToProScreen に遷移していることを確認
  expect(find.byType(UpgradeToProScreen), findsOneWidget);
});
```

### 3. 統合テスト

- プロ版購入後、設定画面に戻った際に正しいプラン表示に更新されることをテストする
- エラー状態の表示が正しく行われることをテストする

## 非機能要件の対応

### 1. パフォーマンス

- プラン情報の取得は非同期で行い、UI 表示をブロックしない
- プラン情報取得中はスケルトンローディングを表示する

### 2. セキュリティ

- プラン情報は RevenueCat を通じてセキュアに管理する
- 不正なプラン変更ができないよう、サーバーサイドでの検証を行う

### 3. ユーザビリティ

- プラン表示は一目で現在の状態がわかるようにする
  - フリー版：標準的なアイコン（`Icons.person`）
  - プロ版：プレミアム感のあるアイコン（`Icons.workspace_premium`）と金色の色
- アップグレードボタンは操作しやすい大きさと配置にする
- アップグレード画面への遷移はスムーズに行う

### 4. アクセシビリティ

- プラン表示には適切なコントラスト比を確保する
- アップグレードボタンには適切なツールチップを設定する
- スクリーンリーダー対応のためのセマンティックラベルを設定する

```dart
// 疑似コード
Semantics(
  label: isPro ? 'あなたは現在プロ版を利用中です' : 'あなたは現在フリー版を利用中です',
  child: _buildPlanInfoTile(context, isPro),
)
```

## 制約事項への対応

- RevenueCat を使用した既存の課金システムを活用する
  - `isProUserProvider` を使用してプラン情報を取得する
  - `UpgradeToProScreen` の既存の実装を利用する
- 現在のアプリデザインとの一貫性を保つ
  - 既存の `ListTile` スタイルを踏襲する
  - アイコンと色の使い分けで視覚的な区別を行う
- Flutter/Riverpod のベストプラクティスに従う実装を行う
  - 状態管理には Riverpod を使用する
  - UI と状態管理を適切に分離する
