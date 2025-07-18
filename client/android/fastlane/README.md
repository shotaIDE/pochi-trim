fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

### install_flutter_dependencies

```sh
[bundle exec] fastlane install_flutter_dependencies
```

Flutterの依存関係をインストールします。

### generate

```sh
[bundle exec] fastlane generate
```

自動コードを生成します。

### bump_beta_version

```sh
[bundle exec] fastlane bump_beta_version
```

前回のベータバージョンからのGit履歴に基づきバージョン名をインクリメントします。

### bump_rc_version

```sh
[bundle exec] fastlane bump_rc_version
```

前回のRCバージョンからのGit履歴に基づきバージョン名をインクリメントします。

### add_beta_tag

```sh
[bundle exec] fastlane add_beta_tag
```

ベータバージョンのタグを追加します。

### add_rc_tag

```sh
[bundle exec] fastlane add_rc_tag
```

RCバージョンのタグを追加します。

### set_full_version_name_from_latest_beta_tag

```sh
[bundle exec] fastlane set_full_version_name_from_latest_beta_tag
```

最新のベータタグに一致するようにバージョン名を変更します。

### set_full_version_name_from_latest_rc_tag

```sh
[bundle exec] fastlane set_full_version_name_from_latest_rc_tag
```

最新のRCタグに一致するようにバージョン名を変更します。

----


## Android

### android build_dev

```sh
[bundle exec] fastlane android build_dev
```

Dev環境向けアプリ(App Bundle)をビルドします。

### android build_prod

```sh
[bundle exec] fastlane android build_prod
```

Prod環境向けアプリ(App Bundle)をビルドします。

### android deploy_dev

```sh
[bundle exec] fastlane android deploy_dev
```

Dev環境向けアプリをGoogle Playにデプロイします。

### android deploy_prod

```sh
[bundle exec] fastlane android deploy_prod
```

Prod環境向けアプリをGoogle Playにデプロイします。

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
