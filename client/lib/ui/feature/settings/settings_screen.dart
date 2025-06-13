import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:pochi_trim/data/definition/app_definition.dart';
import 'package:pochi_trim/data/definition/app_feature.dart';
import 'package:pochi_trim/data/model/delete_account_exception.dart';
import 'package:pochi_trim/data/model/sign_in_result.dart';
import 'package:pochi_trim/data/model/user_profile.dart';
import 'package:pochi_trim/data/service/app_info_service.dart';
import 'package:pochi_trim/data/service/auth_service.dart';
import 'package:pochi_trim/data/service/in_app_purchase_service.dart';
import 'package:pochi_trim/ui/component/color.dart';
import 'package:pochi_trim/ui/feature/pro/upgrade_to_pro_screen.dart';
import 'package:pochi_trim/ui/feature/settings/debug_screen.dart';
import 'package:pochi_trim/ui/feature/settings/section_header.dart';
import 'package:pochi_trim/ui/feature/settings/settings_presenter.dart';
import 'package:skeletonizer/skeletonizer.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  static const name = 'SettingsScreen';

  static MaterialPageRoute<SettingsScreen> route() =>
      MaterialPageRoute<SettingsScreen>(
        builder: (_) => const SettingsScreen(),
        settings: const RouteSettings(name: name),
      );

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: userProfileAsync.when(
        data: (userProfile) {
          if (userProfile == null) {
            return const Center(child: Text('ユーザー情報が取得できませんでした'));
          }

          return ListView(
            children: [
              const SectionHeader(title: 'ユーザー情報'),
              _buildUserInfoTile(context, userProfile),
              const Divider(),
              const SectionHeader(title: 'アプリについて'),
              const _PlanInfoPanel(),
              const _ReviewAppTile(),
              _buildShareAppTile(context),
              _buildTermsOfServiceTile(context),
              _buildPrivacyPolicyTile(context),
              _buildLicenseTile(context),
              if (showDebugFeatures) ...[
                const SectionHeader(title: 'デバッグ'),
                _buildDebugTile(context),
              ],
              const _AppVersionTile(),
              const Divider(),
              const SectionHeader(title: 'アカウント管理'),
              _buildLogoutTile(context),
              _buildDeleteAccountTile(),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('エラーが発生しました: $error')),
      ),
    );
  }

  Widget _buildUserInfoTile(BuildContext context, UserProfile userProfile) {
    final String titleText;
    final Widget? subtitle;
    final VoidCallback? onTap;
    Widget leading;

    switch (userProfile) {
      case UserProfileWithGoogleAccount(
        displayName: final displayName,
        email: final email,
        photoUrl: final photoUrl,
      ):
        leading = photoUrl != null
            ? CircleAvatar(backgroundImage: NetworkImage(photoUrl), radius: 20)
            : const Icon(Icons.person);
        titleText = displayName ?? '名前未設定';
        subtitle = email != null ? Text(email) : null;
        onTap = null;

      case UserProfileWithAppleAccount(
        displayName: final displayName,
        email: final email,
      ):
        leading = const Icon(FontAwesomeIcons.apple);
        titleText = displayName ?? '名前未設定';
        subtitle = email != null ? Text(email) : null;
        onTap = null;

      case UserProfileAnonymous():
        leading = const Icon(Icons.person);
        titleText = 'ゲストユーザー';
        subtitle = null;
        onTap = () => _showAnonymousUserInfoDialog(context);
    }

    return ListTile(
      leading: leading,
      title: Text(titleText),
      subtitle: subtitle,
      onTap: onTap,
    );
  }

  Widget _buildShareAppTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.share),
      title: const Text('友達に教える'),
      onTap: () => ref.read(settingsPresenterProvider).shareApp(),
    );
  }

  Widget _buildTermsOfServiceTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.description),
      title: const Text('利用規約'),
      trailing: const _OpenTrailingIcon(),
      onTap: () async {
        final success = await ref
            .read(settingsPresenterProvider)
            .openTermsOfService();
        if (!success && context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('URLを開けませんでした')));
        }
      },
    );
  }

  Widget _buildPrivacyPolicyTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.privacy_tip),
      title: const Text('プライバシーポリシー'),
      trailing: const _OpenTrailingIcon(),
      onTap: () async {
        final success = await ref
            .read(settingsPresenterProvider)
            .openPrivacyPolicy();
        if (!success && context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('URLを開けませんでした')));
        }
      },
    );
  }

  Widget _buildLicenseTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.description_outlined),
      title: const Text('ライセンス'),
      trailing: const _MoveScreenTrailingIcon(),
      onTap: () => ref.read(settingsPresenterProvider).showLicenses(context),
    );
  }

  Widget _buildDebugTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.bug_report),
      title: const Text('デバッグ画面'),
      trailing: const _MoveScreenTrailingIcon(),
      onTap: () => Navigator.of(context).push(DebugScreen.route()),
    );
  }

  Widget _buildLogoutTile(BuildContext context) {
    final settingsStatus = ref.watch(currentSettingsStatusProvider);
    final isLogoutLoading = settingsStatus == ClearAccountStatus.signingOut;

    return ListTile(
      leading: isLogoutLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.logout, color: Colors.red),
      title: Text(
        isLogoutLoading ? 'ログアウト中...' : 'ログアウト',
        style: const TextStyle(color: Colors.red),
      ),
      onTap: settingsStatus == ClearAccountStatus.none
          ? () => _showLogoutConfirmDialog(context)
          : null,
    );
  }

  Widget _buildDeleteAccountTile() {
    final settingsStatus = ref.watch(currentSettingsStatusProvider);
    final isDeleteLoading =
        settingsStatus == ClearAccountStatus.deletingAccount;

    return ListTile(
      leading: isDeleteLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.delete_forever, color: Colors.red),
      title: Text(
        isDeleteLoading ? 'アカウント削除中...' : 'アカウントを削除',
        style: const TextStyle(color: Colors.red),
      ),
      onTap: settingsStatus == ClearAccountStatus.none
          ? _showDeleteAccountConfirmDialog
          : null,
    );
  }

  void _showAnonymousUserInfoDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        final linkWithGoogleButton = TextButton.icon(
          onPressed: _linkWithGoogle,
          icon: const Icon(FontAwesomeIcons.google),
          label: const Text('Googleと連携'),
        );

        final linkWithAppleButton = TextButton.icon(
          onPressed: _linkWithApple,
          icon: const Icon(FontAwesomeIcons.apple),
          style: TextButton.styleFrom(
            backgroundColor: signInWithAppleBackgroundColor(context),
            foregroundColor: signInWithAppleForegroundColor(context),
          ),
          label: const Text('Appleと連携'),
        );

        final actions = <Widget>[linkWithGoogleButton];

        if (Platform.isIOS) {
          actions.add(linkWithAppleButton);
        }

        actions.add(
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
        );

        return AlertDialog(
          title: const Text('アカウント連携'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('現在、ゲストとしてアプリを利用しています。'),
              SizedBox(height: 8),
              Text('アカウント連携をすると、以下の機能が利用できるようになります：'),
              SizedBox(height: 8),
              Text('• データのバックアップと復元'),
              Text('• 複数のデバイスでの同期'),
              Text('• 家族や友人との家事の共有'),
            ],
          ),
          actions: actions,
        );
      },
    );
  }

  Future<void> _linkWithGoogle() async {
    Navigator.of(context).pop();

    try {
      await ref.read(settingsPresenterProvider).linkWithGoogle();
    } on LinkWithGoogleException catch (error) {
      if (!mounted) {
        return;
      }

      switch (error) {
        case LinkWithGoogleExceptionCancelled():
          return;
        case LinkWithGoogleExceptionAlreadyInUse():
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('このGoogleアカウントは、既に利用されています。別のアカウントでお試しください。'),
            ),
          );
          return;
        case LinkWithGoogleExceptionUncategorized():
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('アカウント連携に失敗しました。しばらくしてから再度お試しください。')),
          );
      }
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('アカウントを連携しました')));
  }

  Future<void> _linkWithApple() async {
    Navigator.of(context).pop();

    try {
      await ref.read(settingsPresenterProvider).linkWithApple();
    } on LinkWithAppleException catch (error) {
      if (!mounted) {
        return;
      }

      switch (error) {
        case LinkWithAppleExceptionCancelled():
          return;
        case LinkWithAppleExceptionAlreadyInUse():
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('このApple IDは、既に利用されています。別のアカウントでお試しください。'),
            ),
          );
          return;
        case LinkWithAppleExceptionUncategorized():
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('アカウント連携に失敗しました。しばらくしてから再度お試しください。')),
          );
      }
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('アカウントを連携しました')));
  }

  // ログアウト確認ダイアログ
  void _showLogoutConfirmDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ログアウト'),
        content: const Text('本当にログアウトしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await ref.read(currentSettingsStatusProvider.notifier).logout();
              } on Exception catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('ログアウトに失敗しました: $e')));
                }
              }
            },
            child: const Text('ログアウト'),
          ),
        ],
      ),
    );
  }

  // アカウント削除確認ダイアログ
  Future<void> _showDeleteAccountConfirmDialog() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('アカウント削除'),
        content: const Text('本当にアカウントを削除しますか？この操作は元に戻せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除する'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      await ref.read(currentSettingsStatusProvider.notifier).deleteAccount();
    } on DeleteAccountException catch (error) {
      if (!mounted) {
        return;
      }

      switch (error) {
        case DeleteAccountExceptionRequiresRecentLogin():
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'アカウント削除には最新のログインが必要です。一度ログアウトして再度ログインしてからお試しください。',
              ),
            ),
          );
        case DeleteAccountExceptionUncategorized():
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('アカウント削除に失敗しました。しばらくしてから再度お試しください。')),
          );
      }
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('アカウントを削除しました')));
  }
}

class _ReviewAppTile extends StatelessWidget {
  const _ReviewAppTile();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.star),
      title: const Text('アプリをレビューする'),
      trailing: const _OpenTrailingIcon(),
      // アプリ内レビューは表示回数に制限があるため、ストアに移動するようにしている
      onTap: () =>
          InAppReview.instance.openStoreListing(appStoreId: appStoreId),
    );
  }
}

class _OpenTrailingIcon extends StatelessWidget {
  const _OpenTrailingIcon();

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.open_in_browser);
  }
}

class _MoveScreenTrailingIcon extends StatelessWidget {
  const _MoveScreenTrailingIcon();

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.arrow_forward_ios, size: 16);
  }
}

class _PlanInfoPanel extends ConsumerWidget {
  const _PlanInfoPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isProFuture = ref.watch(isProUserProvider.future);

    return FutureBuilder(
      future: isProFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const ListTile(
            leading: Icon(Icons.error),
            title: Text('プラン情報の取得に失敗しました'),
          );
        }

        final isPro = snapshot.data;
        return Skeletonizer(
          enabled: isPro == null,
          child: _PlanInfoTile(isPro: isPro ?? false),
        );
      },
    );
  }
}

class _PlanInfoTile extends StatelessWidget {
  const _PlanInfoTile({required this.isPro});

  final bool isPro;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      ListTile(
        leading: Icon(
          isPro ? Icons.workspace_premium : Icons.person,
          color: isPro ? Colors.amber : null,
        ),
        title: Text(
          isPro ? 'Pro版' : 'フリー版',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isPro ? Colors.amber : null,
          ),
        ),
        subtitle: Text(isPro ? '全ての機能が利用可能です' : '一部機能に制限があります'),
      ),
    ];

    if (!isPro) {
      children
        ..add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).push(UpgradeToProScreen.route()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.workspace_premium,
                    color: Colors.amber,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Pro版にアップグレード',
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        ..add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Pro版では家事の登録件数が無制限になります',
              style: TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        );
    }

    return Column(children: children);
  }
}

class _AppVersionTile extends ConsumerWidget {
  const _AppVersionTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appVersionAsync = ref.watch(currentAppVersionProvider);

    final versionString = appVersionAsync.when(
      data: (appVersion) =>
          'バージョン: ${appVersion.version} (${appVersion.buildNumber})',
      loading: () => 'バージョン: n.n.n (nnn)',
      error: (_, _) => 'バージョン情報を取得できませんでした',
    );
    final versionText = Text(
      versionString,
      style: Theme.of(
        context,
      ).textTheme.labelLarge!.copyWith(color: Theme.of(context).dividerColor),
    );

    return Center(
      child: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Skeletonizer(
            enabled: appVersionAsync.isLoading,
            child: versionText,
          ),
        ),
      ),
    );
  }
}
