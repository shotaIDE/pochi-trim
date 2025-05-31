# upgrade_to_pro_screen RevenueCat 商品情報対応の要件定義

## 概要

現在の `upgrade_to_pro_screen` では固定価格（¥980）が表示されているが、RevenueCat から取得した商品情報を元に動的に購入画面を構築する機能を実装する。

## 背景

- 現在の実装では価格が固定値（¥980）でハードコーディングされている
- RevenueCat の PaywallUI を使用しているが、商品情報の取得・表示が不十分
- 価格変更やローカライゼーション対応のため、動的な商品情報取得が必要

## 現状分析

### 既存実装の状況

- **依存関係**: `purchases_flutter: 8.8.1`, `purchases_ui_flutter: 8.8.1` が導入済み
- **AppSession モデル**: `isPro`フラグが既に実装済み
- **購入処理**: `PurchaseProResult`クラスで基本的な購入フローが実装済み
- **UI**: `UpgradeToProScreen`で基本的な UI 構造が実装済み

### 課題

- RevenueCat から商品情報を取得していない
- 価格表示が固定値
- 商品が利用できない場合のエラーハンドリングが不十分
- ローディング状態の管理が不完全

## 要件定義

### 1. 商品情報取得機能

#### 1.1 RevenueCat 商品情報の取得

- RevenueCat の Offerings から商品情報を取得
- 商品 ID: `pro`
- 取得する情報:
  - 商品価格（ローカライズ済み）
  - 商品タイトル
  - 商品説明
  - 通貨情報

#### 1.2 商品情報プロバイダーの実装

- Riverpod を使用した商品情報管理
- 非同期での商品情報取得
- エラー状態の管理
- キャッシュ機能

### 2. UI 表示機能

#### 2.1 動的価格表示

- RevenueCat から取得した価格を表示
- ローカライズされた通貨形式での表示
- 価格取得中のローディング表示

#### 2.2 商品情報表示

- 商品タイトルの動的表示
- 商品説明の表示（必要に応じて）
- 商品が利用できない場合の代替表示

#### 2.3 ローディング状態管理

- 商品情報取得中のスケルトンローディング
- 購入処理中のローディングインジケーター
- 適切なローディング状態の切り替え

### 3. 購入処理機能

#### 3.1 RevenueCat 購入処理の実装

- `Purchases.purchaseProduct()`を使用した購入処理
- 購入結果の適切な処理
- エンタイトルメント確認

#### 3.2 購入状態管理

- 購入処理中の状態管理
- 購入成功時の AppSession 更新
- 購入失敗時のエラーハンドリング

### 4. エラーハンドリング

#### 4.1 商品情報取得エラー

- ネットワークエラー
- RevenueCat 設定エラー
- 商品が見つからない場合

#### 4.2 購入処理エラー

- 購入キャンセル
- 決済エラー
- 既に購入済みの場合

#### 4.3 ユーザーフレンドリーなエラー表示

- 適切な日本語エラーメッセージ
- リトライ機能の提供
- サポートへの誘導

## 技術仕様

### 1. データモデル

#### 1.1 商品情報モデル

```dart
@freezed
class ProProductInfo with _$ProProductInfo {
  const factory ProProductInfo({
    required String productId,
    required String title,
    required String description,
    required String price,
    required String currencyCode,
    required double priceAmount,
  }) = _ProProductInfo;
}
```

#### 1.2 購入状態モデル

```dart
@freezed
class PurchaseState with _$PurchaseState {
  const factory PurchaseState.loading() = PurchaseStateLoading;
  const factory PurchaseState.loaded(ProProductInfo productInfo) = PurchaseStateLoaded;
  const factory PurchaseState.purchasing() = PurchaseStatePurchasing;
  const factory PurchaseState.success() = PurchaseStateSuccess;
  const factory PurchaseState.error(String message) = PurchaseStateError;
}
```

### 2. プロバイダー実装

#### 2.1 商品情報プロバイダー

```dart
@riverpod
class ProProductInfo extends _$ProProductInfo {
  @override
  Future<ProProductInfo?> build() async {
    // RevenueCatから商品情報を取得
  }
}
```

#### 2.2 購入処理プロバイダー

```dart
@riverpod
class PurchaseProPresenter extends _$PurchaseProPresenter {
  @override
  PurchaseState build() => const PurchaseState.loading();

  Future<void> purchasePro() async {
    // 購入処理の実装
  }
}
```

### 3. UI 実装

#### 3.1 価格表示コンポーネント

- 動的価格表示
- ローディング状態対応
- エラー状態表示

#### 3.2 購入ボタンコンポーネント

- 状態に応じたボタン表示
- ローディングインジケーター
- 無効状態の管理

### 4. RevenueCat 設定

#### 4.1 商品設定

- App Store Connect / Google Play Console での商品設定
- RevenueCat ダッシュボードでの商品登録
- エンタイトルメント設定

#### 4.2 API Key 設定

- 既存の`revenue-cat-config.json`を使用
- 環境別の設定管理

## 実装計画

### Phase 1: 基盤実装

1. 商品情報取得サービスの実装
2. データモデルの定義
3. 基本的なプロバイダーの実装

### Phase 2: UI 実装

1. 動的価格表示の実装
2. ローディング状態の実装
3. エラー状態の実装

### Phase 3: 購入処理実装

1. RevenueCat 購入処理の実装
2. 購入状態管理の実装
3. AppSession 更新処理の実装

### Phase 4: エラーハンドリング・最適化

1. 包括的なエラーハンドリング
2. ユーザビリティの向上
3. パフォーマンス最適化

## 関連ファイル

### 修正対象ファイル

- `client/lib/ui/feature/pro/upgrade_to_pro_screen.dart`
- `client/lib/data/service/purchase_pro_result.dart`

### 新規作成ファイル

- `client/lib/data/model/pro_product_info.dart`
- `client/lib/data/service/revenue_cat_service.dart`
- `client/lib/ui/feature/pro/pro_product_presenter.dart`

### 設定ファイル

- `client/revenue-cat-config.json` (既存)

## テスト計画

### 1. 単体テスト

- 商品情報取得処理のテスト
- 購入処理のテスト
- エラーハンドリングのテスト

### 2. ウィジェットテスト

- 価格表示のテスト
- ローディング状態のテスト
- エラー状態のテスト

### 3. 統合テスト

- 購入フロー全体のテスト
- RevenueCat との連携テスト

## 制約事項

- RevenueCat の既存設定を活用
- 現在のアプリデザインとの一貫性を保持
- Flutter/Riverpod のベストプラクティスに準拠
- 既存の AppSession モデルとの互換性を維持

## 成功指標

- 商品情報が正常に取得・表示される
- 購入処理が正常に完了する
- エラー状態が適切に処理される
- ユーザビリティが向上する
- 価格変更に柔軟に対応できる
