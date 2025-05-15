# インフラストラクチャ管理

このディレクトリには、PochiTrim アプリケーションのインフラストラクチャを管理するための Terraform コードが含まれています。

## 環境

- **開発環境（Dev）**: `environments/dev/`
- **本番環境（Prod）**: `environments/prod/`

## 前提条件

- Terraform のインストール
  - https://developer.hashicorp.com/terraform/install
- Google Cloud CLI のインストール
  - https://cloud.google.com/sdk/docs/install-sdk?hl=ja

## 開発環境のデプロイ

```shell
# 開発環境ディレクトリに移動
cd environments/dev

# 初期化
terraform init

# 計画
terraform plan

# 適用
terraform apply
```

## 本番環境のデプロイ

```shell
# 本番環境ディレクトリに移動
cd environments/prod

# 初期化
terraform init

# 計画
terraform plan

# 適用
terraform apply
```

## モジュール構造

このプロジェクトは以下のモジュールで構成されています：

- **firebase**: Google Cloud プロジェクトの作成と Firebase プロジェクトの設定
- **firestore**: Firestore データベースとルールの設定
- **auth**: Firebase 認証の設定
- **app**: iOS と Android アプリの設定

各環境（dev/prod）は、これらのモジュールを使用して独自の設定を行います。

## Firebase エミュレータの起動

```shell
firebase use default
firebase emulators:start --import=./emulator-data --export-on-exit=./emulator-data
```
