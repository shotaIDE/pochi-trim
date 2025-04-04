# 開発貢献ガイド

このドキュメントでは、House Worker プロジェクトの開発に貢献するための手順を説明します。

## 目次

- [開発環境のセットアップ](#開発環境のセットアップ)
- [初期プロジェクト設定](#初期プロジェクト設定)
  - [Flavor の設定](#flavor-の設定)
  - [ツールのバージョン固定](#ツールのバージョン固定)
  - [Firebase プロジェクト情報の追加](#firebase-プロジェクト情報の追加)
  - [アイコンの設定](#アイコンの設定)
  - [fastlane の設定](#fastlane-の設定)
  - [Android のリリースビルドの設定](#android-のリリースビルドの設定)
- [Firebase emulator の設定](#firebase-emulator-の設定)
  - [Firebase emulator のサーバーをローカルマシンで実行する](#firebase-emulator-のサーバーをローカルマシンで実行する)
  - [Firebase emulator に向けたクライアントアプリを実行する](#firebase-emulator-に向けたクライアントアプリを実行する)
- [デプロイ](#デプロイ)
  - [App Store へのデプロイ](#app-store-へのデプロイ)
  - [Google Play へのデプロイ](#google-play-へのデプロイ)

## 開発環境のセットアップ

### 必要条件

- Flutter SDK
- Firebase CLI
- Android Studio / Xcode（モバイル開発用）

## 初期プロジェクト設定

以下の設定は、プロジェクトの初期構築時に実施した手順です。通常の開発作業では参照する必要はありません。

### Flavor の設定

Flavor を追加する場合は、以下の公式ドキュメントに従ってセットアップしてください。
Xcode 上でスキームの設定を行ってください。

https://docs.flutter.dev/deployment/flavors-ios

### ツールのバージョン固定

Xcode のバージョンを強制するには、以下の手順を実行してください。

https://qiita.com/manicmaniac/items/5294dd16cd6f835ab2d9

### Firebase プロジェクト情報の追加

#### 事前準備

Firebase CLI のインストールとログイン、FlutterFire CLI のインストールが必要です。以下を参照してください。

https://firebase.google.com/docs/flutter/setup?hl=ja&platform=ios#install-cli-tools

#### 環境別の設定更新手順

以下の共通変数を設定します：

```shell
PROJECT_ID_BASE="colomney-house-worker"
APPLICATION_ID_BASE="ide.shota.colomney.HouseWorker"
```

各環境ごとに以下の変数を設定し、共通のコマンドを実行します：

##### Emulator 環境の設定

```shell
# 環境固有の変数設定
PROJECT_ID_SUFFIX="-emulator"
APPLICATION_ID_SUFFIX=".emulator"
DART_FILE_NAME_SUFFIX="_emulator"
DIRECTORY_NAME_FOR_IOS="Emulator"
DIRECTORY_NAME_FOR_ANDROID="emulator"
PROJECT_ID="${PROJECT_ID_BASE}${PROJECT_ID_SUFFIX}"
APPLICATION_ID="${APPLICATION_ID_BASE}${APPLICATION_ID_SUFFIX}"
```

実行時、プロンプトの選択肢では以下を選んでください：

- "Build configuration"
- "Debug-emulator"

##### Dev 環境の設定

```shell
# 環境固有の変数設定
PROJECT_ID_SUFFIX="-dev"
APPLICATION_ID_SUFFIX=".dev"
DART_FILE_NAME_SUFFIX="_dev"
DIRECTORY_NAME_FOR_IOS="Dev"
DIRECTORY_NAME_FOR_ANDROID="dev"
PROJECT_ID="${PROJECT_ID_BASE}${PROJECT_ID_SUFFIX}"
APPLICATION_ID="${APPLICATION_ID_BASE}${APPLICATION_ID_SUFFIX}"
```

実行時、プロンプトの選択肢では以下を選んでください：

- "Build configuration"
- "Debug-dev"

##### Prod 環境の設定

```shell
# 環境固有の変数設定
PROJECT_ID_SUFFIX=""
APPLICATION_ID_SUFFIX=""
DART_FILE_NAME_SUFFIX="_prod"
DIRECTORY_NAME_FOR_IOS="Prod"
DIRECTORY_NAME_FOR_ANDROID="prod"
PROJECT_ID="${PROJECT_ID_BASE}${PROJECT_ID_SUFFIX}"
APPLICATION_ID="${APPLICATION_ID_BASE}${APPLICATION_ID_SUFFIX}"
```

##### 共通のコマンド実行

環境ごとの変数を設定した後、以下の共通コマンドを実行します：

```shell
# Firebaseの設定ファイル生成
cd client/
flutterfire config \
  --project="${PROJECT_ID}" \
  --out="lib/firebase_options${DART_FILE_NAME_SUFFIX}.dart" \
  --ios-bundle-id="${APPLICATION_ID}" \
  --ios-out="ios/Runner/Firebase/${DIRECTORY_NAME_FOR_IOS}/GoogleService-Info.plist" \
  --android-package-name="${APPLICATION_ID}" \
  --android-out="android/app/src/${DIRECTORY_NAME_FOR_ANDROID}/google-services.json"
```

### アイコンの設定

iOS、Android ともに、flutter_launcher_icons ライブラリを利用して生成します。
ライブラリが参照する設定ファイルは、以下の通りです。

- [flutter_launcher_icons-emulator.yaml](client/flutter_launcher_icons-emulator.yaml)
- [flutter_launcher_icons-dev.yaml](client/flutter_launcher_icons-dev.yaml)
- [flutter_launcher_icons-prod.yaml](client/flutter_launcher_icons-prod.yaml)

以下を参考に設定してください。
コマンド実行後 iOS に適用するには、Xcode の"User-Defined Setting"により、構成ごとのアイコン名を定義し、設定する必要があります。

https://pub.dev/packages/flutter_launcher_icons#2-run-the-package

### fastlane の設定

以下を参考に、fastlane を設定します。

https://docs.flutter.dev/deployment/cd#fastlane

### Android のリリースビルドの設定

以下を参考に設定します。

https://docs.flutter.dev/deployment/android#sign-the-app

## Firebase emulator の設定

### Firebase emulator のサーバーをローカルマシンで実行する

[「Firebase CLI をインストールする」](https://firebase.google.com/docs/cli#install_the_firebase_cli)を参考に、Firebase CLI をインストールします。

以下コマンドを実行します。

```shell
cd infra
firebase emulators:start --import=emulator-data --export-on-exit=emulator-data
```

上記により、`infra/emulator-data/` フォルダーに Firebase Emulator のデータが保持されます。
リセットしたい場合は、フォルダーごと削除してください。

### Firebase emulator に向けたクライアントアプリを実行する

プロジェクトには`client/emulator-config.sample.json`というサンプルファイルが含まれています。
このファイルをコピーして`client/emulator-config.json`を作成してください。
この手順はマシンごとに 1 回だけ必要です。

```shell
cp client/emulator-config.sample.json client/emulator-config.json
```

作成した`client/emulator-config.json`ファイルには以下の形式で設定が記述されています：

```json
{
  "EMULATOR_HOST": "127.0.0.1"
}
```

必要に応じて`EMULATOR_HOST`の値を変更してください。デフォルト値は`127.0.0.1`です。

> **注意**: `emulator-config.json`は gitignore に設定されており、リポジトリにはコミットされません。各開発者が自分の環境に合わせて設定する必要があります。

次に、VSCode の「実行とデバッグ」パネルから"Emulator-Debug"などの構成を選択して実行してください。
プロジェクトには適切な起動構成が含まれており、自動的に `--dart-define-from-file=client/emulator-config.json` 引数を使用して設定ファイルを読み込みます。

## デプロイ

### App Store へのデプロイ

App Store Connect でアプリを作成します。

また、Apple Developer Console で Bundle Identifier とプロビジョニングプロファイルを登録しておきます。
Xcode で一旦 Automatically Signing により App Store ビルドを Export することで、各種 Capability が付与された Bundle Identifier が自動で登録されるので、それを利用すると少し楽です。
プロビジョニングプロファイルは手動で登録します。

:::message
配布するアプリを Automatically Signing でビルドすると機能が有効化されていないなどのトラブルに見舞われることが多いので、Manual Signing を採用します。
:::

Manual Signing で Export した際に出力された plist を [client/ios/ExportOptions.plist](client/ios/ExportOptions.plist) に配置してください。

最後に App Store Connect API キーを発行し、[client/ios/fastlane/app-store-connect-api-key.p8](client/ios/fastlane/app-store-connect-api-key.p8) に配置してください。
以下を参考にしてください。

https://docs.fastlane.tools/app-store-connect-api/

fastlane からアップロードして外部テスト公開まで行うには、1 度外部テストに審査を実施して公開しておく必要があります。

### Google Play へのデプロイ

以下を参考にして、デプロイ用のサービスアカウントキー(JSON)を用意し、[client/android/fastlane/google-play-service-account-key.json](client/android/fastlane/google-play-service-account-key.json) に配置してください。

https://docs.fastlane.tools/actions/upload_to_play_store/

fastlane からアップロードするには、1 度手動で Google Play に aab ファイルをアップロードし、内部テスターに公開しておく必要があります。

また、fastlane からアップロードして公開まで行うには、1 度クローズドテストに審査を実施して公開しておく必要があります。
