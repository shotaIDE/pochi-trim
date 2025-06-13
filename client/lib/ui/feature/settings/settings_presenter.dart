import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pochi_trim/data/model/delete_account_exception.dart';
import 'package:pochi_trim/data/service/auth_service.dart';
import 'package:pochi_trim/ui/root_presenter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

part 'settings_presenter.g.dart';

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

  /// ログアウト処理
  Future<void> logout() async {
    await _ref.read(authServiceProvider).signOut();
    await _ref.read(currentAppSessionProvider.notifier).signOut();
  }

  /// アカウント削除処理
  Future<DeleteAccountResult> deleteAccount() async {
    try {
      // アカウントの削除
      await _ref.read(authServiceProvider).deleteAccount();

      // アプリセッションのクリア
      await _ref.read(currentAppSessionProvider.notifier).signOut();

      return const DeleteAccountResult.success();
    } on DeleteAccountException catch (error) {
      switch (error) {
        case DeleteAccountExceptionRequiresRecentLogin():
          return const DeleteAccountResult.requiresRecentLogin();
        case DeleteAccountExceptionUncategorized():
          return const DeleteAccountResult.uncategorized();
      }
    } on Exception catch (e) {
      return DeleteAccountResult.generalError('$e');
    }
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
    final url = Uri.parse('https://example.com/terms');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
      return true;
    }
    return false;
  }

  /// プライバシーポリシーを開く
  Future<bool> openPrivacyPolicy() async {
    final url = Uri.parse('https://example.com/privacy');
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
