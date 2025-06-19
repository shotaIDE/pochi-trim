import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pochi_trim/data/definition/app_definition.dart';
import 'package:pochi_trim/data/service/auth_service.dart';
import 'package:pochi_trim/ui/root_presenter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

part 'settings_presenter.g.dart';

/// ログアウトやアカウント削除などの処理状態
enum ClearAccountStatus {
  /// 何も実行していない
  none,

  /// ログアウト中
  signingOut,

  /// アカウント削除中
  deletingAccount,
}

/// 現在の設定画面の処理状態を管理する
@riverpod
class CurrentSettingsStatus extends _$CurrentSettingsStatus {
  @override
  ClearAccountStatus build() => ClearAccountStatus.none;

  /// ログアウト処理
  Future<void> logout() async {
    state = ClearAccountStatus.signingOut;

    try {
      await ref.read(authServiceProvider).signOut();

      await ref.read(currentAppSessionProvider.notifier).signOut();
    } finally {
      state = ClearAccountStatus.none;
    }
  }

  /// アカウント削除処理
  Future<void> deleteAccount() async {
    state = ClearAccountStatus.deletingAccount;

    try {
      // アカウントの削除
      await ref.read(authServiceProvider).deleteAccount();

      // アプリセッションのクリア
      await ref.read(currentAppSessionProvider.notifier).signOut();
    } finally {
      state = ClearAccountStatus.none;
    }
  }
}

@riverpod
SettingsPresenter settingsPresenter(Ref ref) {
  return SettingsPresenter(ref);
}

class SettingsPresenter {
  SettingsPresenter(this._ref);

  final Ref _ref;

  /// Googleアカウントと連携する
  Future<void> linkWithGoogle() async {
    await _ref.read(authServiceProvider).linkWithGoogle();
  }

  /// Appleアカウントと連携する
  Future<void> linkWithApple() async {
    await _ref.read(authServiceProvider).linkWithApple();
  }

  /// アプリを共有する
  void shareApp() {
    SharePlus.instance.share(
      ShareParams(
        text:
            // TODO(ide): アプリのURLを取得する
            '家事の可視化と削減アプリ「ぽちそぎ」を使ってみませんか？ ',
        title: '家事の可視化と削減アプリ「ぽちそぎ」',
      ),
    );
  }

  /// 利用規約を開く
  Future<bool> openTermsOfService() async {
    final url = Uri.parse(termsOfServiceUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
      return true;
    }
    return false;
  }

  /// プライバシーポリシーを開く
  Future<bool> openPrivacyPolicy() async {
    final url = Uri.parse(privacyPolicyUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
      return true;
    }
    return false;
  }

  /// ライセンス画面を表示する
  void showLicenses(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: 'ぽちそぎ',
      applicationLegalese: '2025 colomney',
    );
  }
}
