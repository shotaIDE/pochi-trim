# Sign in with Apple 要件定義

## 概要

「Sign in with Apple」機能を実装し、ユーザーが Apple アカウントを使用してアプリケーションにサインインできるようにします。これにより、ユーザーの選択肢を増やし、特に iOS デバイスユーザーの利便性を向上させます。

## 背景

- 現在のアプリケーションでは、Google アカウントでのサインインと匿名サインインが実装されています
- iOS アプリでは、App Store のガイドラインにより、ソーシャルログインを提供する場合は「Sign in with Apple」も提供する必要があります
- ユーザーのプライバシー保護意識の高まりに対応するため、Apple のプライバシー重視の認証オプションを提供することが重要です

## 機能要件

### ユーザーストーリー

1. **新規ユーザーとして**、Apple アカウントを使用してアプリにサインアップしたい
2. **既存ユーザーとして**、Apple アカウントを使用してアプリにサインインしたい
3. **匿名ユーザーとして**、自分のデータを保持したまま Apple アカウントと連携したい

### 機能詳細

#### サインイン画面

- ログイン画面に「Apple でサインイン」ボタンを追加
- ボタンのデザインは Apple のガイドラインに準拠
- Apple サインインフローの実装
  - Apple の認証画面表示
  - ユーザー情報の取得と処理
  - Firebase Authentication との連携

#### 設定画面

- 匿名ユーザーの場合、「Apple アカウントと連携」オプションを追加
- ユーザープロファイル表示に Apple アカウント情報を対応
- アカウント連携機能の実装

#### エラーハンドリング

- サインインキャンセル時の処理
- サインイン失敗時のエラーメッセージ表示
- 既に使用されている Apple アカウントでの連携試行時の処理

## 技術要件

### 必要なライブラリ/パッケージ

- `sign_in_with_apple`: Apple サインインを実装するための Flutter パッケージ
- `firebase_auth`: Firebase 認証との連携

### バックエンド要件

- Firebase Authentication の設定更新
  - Apple 認証プロバイダーの有効化
- Apple デベロッパーアカウントでの設定
  - App ID 設定
  - サービス ID 設定
  - 秘密鍵の生成

### データモデル変更

- `UserProfile`クラスの拡張
  - `UserProfileWithAppleAccount`の追加
- `SignInResult`の拡張
- `SignInWithAppleException`の定義

## UI デザイン要件

- Apple のデザインガイドラインに準拠したサインインボタン
  - 黒背景に白文字のボタン（ダークモード対応）
  - Apple ロゴの表示
  - 適切なサイズとパディング
- 既存の Google サインインボタンとの視覚的バランス
- アクセシビリティ対応（スクリーンリーダー対応など）

## セキュリティ要件

- Apple から提供される ID トークンの検証
- ユーザー情報の安全な保存
- プライバシー保護対応
  - Apple の「メールを隠す」機能への対応
  - プライバシーポリシーの更新

## テスト要件

- ユニットテスト
  - `AuthService`の拡張部分のテスト
  - 例外処理のテスト
- 統合テスト
  - サインインフローのテスト
  - アカウント連携のテスト
- 手動テスト
  - 実際の iOS デバイスでのテスト
  - 異なる iOS バージョンでのテスト

## 制約事項

- Apple サインインは主に iOS デバイスでの利用を想定
- Android デバイスでも技術的には可能だが、UX が最適でない可能性がある
- Apple の認証情報（名前、メール）は初回サインイン時のみ提供される可能性があるため、適切に保存する必要がある

## 実装上の注意点

- Apple サインインは、iOS バージョン 13 以上が必要
- Web プラットフォームでの対応も検討する場合は追加の実装が必要
- Firebase Authentication との連携方法の確認
- アプリのバンドル ID と Apple デベロッパーアカウントの設定の一致確認

## 今後の拡張性

- 複数のソーシャルアカウント連携機能
- アカウント切り替え機能
- アカウント連携解除機能
