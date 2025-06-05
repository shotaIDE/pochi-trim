# 開発貢献ガイド

このドキュメントでは、House Worker プロジェクトの開発に貢献するための手順を説明します。

## 開発環境のセットアップ

### 必要条件

- Flutter SDK
- Firebase CLI
- Android Studio / Xcode（モバイル開発用）

## 初期プロジェクト設定

以下の設定は、プロジェクトの初期構築時に実施した手順です。通常の開発作業では参照する必要はありません。

### Flavor の設定

Flavor を追加する場合は、以下の公式ドキュメントに従ってセットアップしてください。
Xcode 上でスキームの設定を行ってください。また、独自のビルド設定を追加する手順も必要です。

https://docs.flutter.dev/deployment/flavors-ios

### ツールのバージョン固定

Xcode のバージョンを強制するには、以下の手順を実行してください。

https://qiita.com/manicmaniac/items/5294dd16cd6f835ab2d9

### Flutter アプリへの Firebase プロジェクト構成の追加

#### 事前準備

Firebase CLI のインストールとログイン、FlutterFire CLI のインストールが必要です。以下を参照してください。

https://firebase.google.com/docs/flutter/setup?hl=ja&platform=ios#install-cli-tools

#### 環境別の設定更新手順

以下の共通変数を設定します：

```shell
PROJECT_ID_BASE="colomney"
APPLICATION_ID_BASE="ide.shota.colomney"
```

各環境ごとに以下の変数を設定し、共通のコマンドを実行します：

##### Emulator 環境の設定

```shell
# 環境固有の変数設定
PROJECT_ID_SUFFIX="-house-worker-dev-tf1"
APPLICATION_ID_SUFFIX=".HouseWorker.emulator"
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
PROJECT_ID_SUFFIX="-house-worker-dev-tf1"
APPLICATION_ID_SUFFIX=".HouseWorker.dev"
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
PROJECT_ID_SUFFIX="-pochi-trim"
APPLICATION_ID_SUFFIX=".PochiTrim"
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

### Firebase プロジェクトの手動設定

Terraform で作成した Firebase プロジェクトに、Firebase Console から手動で以下の設定を行います。

- Google アナリティクスの有効化
- Remote Config でパラメータを設定
- Authentication におけるログインプロバイダを設定し、FlutterFire CLI による Firebase プロジェクト構成の再構成を行う
  - 再構成が必要なタイミングは公式ドキュメントを参照
    - https://firebase.google.com/docs/flutter/setup?platform=ios&hl=ja#configure-firebase
  - Google アカウントのログインプロバイダを設定する場合、SHA-1 フィンガープリントを登録する必要がある。Firebase Emulator 環境においても同様に登録が必要。
    - https://developers.google.com/android/guides/client-auth?hl=ja#using_keytool_on_the_certificate
  - Apple アカウントのログインプロバイダを設定する場合、Xcode 上で Release 構成は Manual Signing に設定しておく必要がある。
    - Xcode 上では Automatic Signing 状態で、コマンドにより Manual Signing に付け替えて App Store 向けのビルドを行うと、Apple でサインイン機能が原因不明のエラーで失敗する。そのため、付け替えでなく最初から Manual Signing に設定しておく必要がある。
    - https://zenn.dev/colomney/scraps/c6a503fad4da72

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

### RevenueCat の設定

RevenueCat のダッシュボードで、本番環境のアプリを束ねる 1 つのプロジェクトを作成します。

プロジェクト内で App Store と Google Play のアプリを作成します。
以下を参考に必要な設定をストアから取得します。

https://www.revenuecat.com/docs/projects/connect-a-store

プロジェクトには`client/revenue-cat-config.sample.json`というサンプルファイルが含まれています。
このファイルをコピーして`client/revenue-cat-config.json`を作成してください。

本番環境のアプリをビルドし、App Store と Google Play にそれぞれアップロードします。
課金アイテムを作成するために、アプリのアップロードや審査提出が必要なためです。

以下を参考に課金アイテムを AppStore と Google Play それぞれに作成します。

https://www.revenuecat.com/docs/offerings/products/setup-index

具体的には、以下の手順を実行します。

1. Entitlement(アプリ内で課金によって解放される資格)を RevenueCat のダッシュボードで作成します。
2. App Store Connect でアプリを作成し、アプリ専用の課金アイテムを作成し、下書き状態としておきます
3. Google Play Console でアプリを作成し、アプリ専用の課金アイテムを作成します。
4. RevenueCat のダッシュボードで、App Store と Google Play で作成した課金アイテムを Product(アプリ内で購入できる単位)としてインポートします。
5. RevenueCat のダッシュボードで、Entitlement と Product を紐付けます。

:::message
上記だけだとまだ課金処理が実装できないため、調査が必要です。
:::

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

Manual Signing で Export した際に出力された plist を環境ごとに以下のファイルに配置してください：

- Dev 環境: [client/ios/ExportOptions_dev.plist](client/ios/ExportOptions_dev.plist)
- Prod 環境: [client/ios/ExportOptions_prod.plist](client/ios/ExportOptions_prod.plist)

最後に App Store Connect API キーを発行し、[client/ios/fastlane/app-store-connect-api-key.p8](client/ios/fastlane/app-store-connect-api-key.p8) に配置してください。
以下を参考にしてください。

https://docs.fastlane.tools/app-store-connect-api/

fastlane からアップロードして外部テスト公開まで行うには、1 度外部テストに審査を実施して公開しておく必要があります。

### Google Play へのデプロイ

以下を参考にして、デプロイ用のサービスアカウントキー(JSON)を用意し、[client/android/fastlane/google-play-service-account-key.json](client/android/fastlane/google-play-service-account-key.json) に配置してください。

https://docs.fastlane.tools/actions/upload_to_play_store/

fastlane からアップロードするには、1 度手動で Google Play に aab ファイルをアップロードし、内部テスターに公開しておく必要があります。

また、fastlane からアップロードして公開まで行うには、1 度クローズドテストに審査を実施して公開しておく必要があります。

クローズドテストへの審査では、以下のような設定を行います。

- 広告 ID を分析で利用していると申告
