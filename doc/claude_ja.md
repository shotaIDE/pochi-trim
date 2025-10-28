# 絶対に守るべきルール

## コード修正を行う前

コード修正を行う前に、必ず以下を実施する。

1. 関連すると考えられるコーディング規約を確認する。開発規約は以下に配置されている。

- [doc/coding-rule/](/doc/coding-rule/)

2. 類似する既存コードを 5 件程度確認する。

## コード修正を行った後

コード修正を行った後に、必ず以下を実施する。

1. フォーマッタを適用する。実行コマンドは以下の通り。

```bash
dart format path/to/your/file.dart
```

2. Linter の自動修正を適用する。実行コマンドは以下の通り。

```bash
dart fix --apply
```

3. Linter やコンパイラの警告を必ず確認する。警告が発生している場合は、解決する。

4. ユニットテストを実行し、全てのテストが通過することを確認する。

5. ドキュメント類の修正が必要な場合は、修正する。

6. 適切なコミットメッセージを考え、コミットする。

# アーキテクチャ

本プロジェクトは、iOS と Android のアプリケーションであり、フロントエンドとバックエンドのコードを含む。

## クライアントアプリ

`client/` は、Flutter による iOS と Android クライアントアプリのコードを配置する。

- [`./android/`](/client/android/): Android 専用のプロダクトコードやプロジェクト設定
- [`./ios/`](/client/ios/): iOS 専用のプロダクトコードやプロジェクト設定
- [`./lib/`](/client/lib/): OS 間で共通のプロダクトコード
  - [`./data/`](/client/lib/data/): 情報の保持・取得や、OS レイヤーとのやりとり
    - [`./definition/`](/client/lib/data/definition/): 情報の保持・取得や、OS レイヤーとのやりとりに利用する共通化された定義
    - [`./model/`](/client/lib/data/model/): ドメインモデル。UI に依存しない純粋なデータ構造や、UI に依存しない `Exception`、`Error` などを配置する。
    - [`./repository/`](/client/lib/data/repository/): Repository。具体的な向き先を抽象化しつつ、情報の保持・取得を行う処理の定義
    - [`./service/`](/client/lib/data/service/): Service。OS や Firebase との接続を定義
  - [`./ui/`](/client/lib/ui/): 画面描画や表示ロジックの定義
    - [`./component/`](/client/lib/ui/component/): 画面間で共通化された UI 部品の定義
    - [`./feature/`](/client/lib/ui/feature/): 画面と画面ロジック。カテゴリーごとのサブフォルダーが存在する。
- [`./test/`](/client/test/): ユニットテスト、ウィジェットテスト

本アプリでは、Swift Package Manager(SPM) を有効化しており、CocoaPods と併用している。
SPM は以下のコマンドにより、Flutter 本体で有効化している。

```bash
flutter config --enable-swift-package-manager
```

SPM はベータ版機能であるため、ビルドなどで問題が発生することがある。
その際は、Flutter の報告されている Issue を調査したり、未知の問題が発生している可能性があることを考慮するなどにより、トラブルシューティングを行う。

## インフラ

`infra/` は、インフラ構成とバックエンドのコードを配置する。
