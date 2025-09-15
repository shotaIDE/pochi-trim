# インフラとバックエンド

このディレクトリには、アプリケーションのインフラストラクチャを管理するための Terraform コードと、バックエンドのコードが含まれています。

## インフラ

### 環境

- **開発環境（Dev）**: `environment/dev/`
- **本番環境（Prod）**: `environment/prod/`

### 前提条件

- Terraform のインストール
  - https://developer.hashicorp.com/terraform/install
- Google Cloud CLI のインストール
  - https://cloud.google.com/sdk/docs/install-sdk?hl=ja
- Google Cloud CLI の認証
  - https://developer.hashicorp.com/terraform/tutorials/gcp-get-started/google-cloud-platform-build#authenticate-to-google-cloud

### プロジェクト固有の識別子設定

`*.tf` ファイル内の以下の識別子を、プロジェクトに合わせて修正してください。

- Google Cloud のプロジェクト ID のベース部分: `flu-fire-base`
- Bundle ID / アプリ ID のベース部分: `FlutterFirebaseBase`

### 開発環境のデプロイ

`environment/dev/terraform.tfvars` ファイルに必要な変数を設定した後、以下のコマンドを実行します。

```shell
# 開発環境ディレクトリに移動
cd environment/dev

# 初期化
terraform init

# 計画
terraform plan

# 適用
terraform apply
```

### 本番環境のデプロイ

`environment/prod/terraform.tfvars` ファイルに必要な変数を設定した後、以下のコマンドを実行します。

```shell
# 本番環境ディレクトリに移動
cd environment/prod

# 初期化
terraform init

# 計画
terraform plan

# 適用
terraform apply
```

### モジュール構造

このプロジェクトは以下のモジュールで構成されています：

- **firebase**: Google Cloud プロジェクトの作成と Firebase プロジェクトの設定
- **firestore**: Firestore データベースとルールの設定
- **auth**: Firebase 認証の設定
- **app**: iOS と Android アプリの設定

各環境（dev/prod）は、これらのモジュールを使用して独自の設定を行います。

## バックエンド

バックエンドは Firebase Functions を使用しており、以下のディレクトリにコードが格納されています：

- **functions**: Firebase Functions のコード

### Firebase Functions のデプロイ

Firebase Functions は Terraform で管理されていないため、手動でデプロイする必要があります。

```shell
# 開発環境へのデプロイ
firebase use default
firebase deploy --only functions

# 本番環境へのデプロイ
firebase use prod
firebase deploy --only functions
```

## Firebase エミュレータの起動

```shell
firebase use default
firebase emulators:start --import=./emulator-data --export-on-exit=./emulator-data
```
