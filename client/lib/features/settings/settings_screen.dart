import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/models/user_profile.dart';
import 'package:house_worker/root_presenter.dart';
import 'package:house_worker/services/auth_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

// アプリのバージョン情報を取得するプロバイダー
final packageInfoProvider = FutureProvider<PackageInfo>((ref) {
  return PackageInfo.fromPlatform();
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const name = 'SettingsScreen';

  static MaterialPageRoute<SettingsScreen> route() =>
      MaterialPageRoute<SettingsScreen>(
        builder: (_) => const SettingsScreen(),
        settings: const RouteSettings(name: name),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(currentUserProfileProvider);
    final packageInfoAsync = ref.watch(packageInfoProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: userProfileAsync.when(
        data: (userProfile) {
          if (userProfile == null) {
            return const Center(child: Text('ユーザー情報が取得できませんでした'));
          }

          return ListView(
            children: [
              _buildSectionHeader(context, 'ユーザー情報'),
              _buildUserInfoTile(context, userProfile, ref),
              const Divider(),
              _buildSectionHeader(context, 'アプリについて'),
              _buildReviewTile(context),
              _buildShareAppTile(context),
              _buildTermsOfServiceTile(context),
              _buildPrivacyPolicyTile(context),
              _buildLicenseTile(context),
              _buildSectionHeader(context, 'デバッグ'),
              _buildDebugTile(context),
              _buildVersionInfo(context, packageInfoAsync),
              const Divider(),
              _buildSectionHeader(context, 'アカウント管理'),
              _buildLogoutTile(context, ref),
              _buildDeleteAccountTile(context, ref, userProfile),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('エラーが発生しました: $error')),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildUserInfoTile(
    BuildContext context,
    UserProfile userProfile,
    WidgetRef ref,
  ) {
    final String subtitle;
    final VoidCallback? onTap;

    switch (userProfile) {
      case UserProfileAnonymous():
        subtitle = 'ゲスト';
        onTap = () => _showAnonymousUserInfoDialog(context);
      case UserProfileWithAccount(displayName: final displayName):
        subtitle = displayName ?? '名前未設定';
        onTap = null;
    }

    return ListTile(
      leading: const Icon(Icons.person),
      title: const Text('ユーザー名'),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }

  Widget _buildReviewTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.star),
      title: const Text('アプリをレビューする'),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () async {
        // レビューページへのリンク
        final url = Uri.parse(
          'https://play.google.com/store/apps/details?id=com.example.houseworker',
        );
        if (await canLaunchUrl(url)) {
          await launchUrl(url);
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('URLを開けませんでした')));
          }
        }
      },
    );
  }

  Widget _buildShareAppTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.share),
      title: const Text('友達に教える'),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        // シェア機能
        Share.share(
          '家事管理アプリ「House Worker」を使ってみませんか？ https://example.com/houseworker',
        );
      },
    );
  }

  Widget _buildTermsOfServiceTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.description),
      title: const Text('利用規約'),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () async {
        // 利用規約ページへのリンク
        final url = Uri.parse('https://example.com/terms');
        if (await canLaunchUrl(url)) {
          await launchUrl(url);
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('URLを開けませんでした')));
          }
        }
      },
    );
  }

  Widget _buildPrivacyPolicyTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.privacy_tip),
      title: const Text('プライバシーポリシー'),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () async {
        // プライバシーポリシーページへのリンク
        final url = Uri.parse('https://example.com/privacy');
        if (await canLaunchUrl(url)) {
          await launchUrl(url);
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('URLを開けませんでした')));
          }
        }
      },
    );
  }

  Widget _buildLicenseTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.description_outlined),
      title: const Text('ライセンス'),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        // ライセンス表示画面へ遷移
        showLicensePage(
          context: context,
          applicationName: 'House Worker',
          applicationLegalese: ' 2025 House Worker',
        );
      },
    );
  }

  Widget _buildDebugTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.bug_report),
      title: const Text('デバッグ画面'),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        // デバッグ画面への遷移処理
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('デバッグ画面は現在開発中です')));
      },
    );
  }

  Widget _buildVersionInfo(
    BuildContext context,
    AsyncValue<PackageInfo> packageInfoAsync,
  ) {
    return packageInfoAsync.when(
      data: (packageInfo) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'バージョン: ${packageInfo.version} (${packageInfo.buildNumber})',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        );
      },
      loading: () => const Center(child: Text('バージョン情報を読み込み中...')),
      error: (_, _) => const Center(child: Text('バージョン情報を取得できませんでした')),
    );
  }

  Widget _buildLogoutTile(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.logout, color: Colors.red),
      title: const Text('ログアウト', style: TextStyle(color: Colors.red)),
      onTap: () => _showLogoutConfirmDialog(context, ref),
    );
  }

  Widget _buildDeleteAccountTile(
    BuildContext context,
    WidgetRef ref,
    UserProfile userProfile,
  ) {
    return ListTile(
      leading: const Icon(Icons.delete_forever, color: Colors.red),
      title: const Text('アカウントを削除', style: TextStyle(color: Colors.red)),
      onTap: () => _showDeleteAccountConfirmDialog(context, ref, userProfile),
    );
  }

  // 匿名ユーザー情報ダイアログ
  void _showAnonymousUserInfoDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('匿名ユーザー情報'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('現在、匿名ユーザーとしてログインしています。'),
                SizedBox(height: 8),
                Text('アカウント登録をすると、以下の機能が利用できるようになります：'),
                SizedBox(height: 8),
                Text('• データのバックアップと復元'),
                Text('• 複数のデバイスでの同期'),
                Text('• 家族や友人との家事の共有'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('閉じる'),
              ),
            ],
          ),
    );
  }

  // ログアウト確認ダイアログ
  void _showLogoutConfirmDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('ログアウト'),
            content: const Text('本当にログアウトしますか？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('キャンセル'),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    await ref.read(authServiceProvider).signOut();
                    await ref
                        .read(currentAppSessionProvider.notifier)
                        .signOut();
                  } on Exception catch (e) {
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('ログアウトに失敗しました: $e')),
                      );
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
  void _showDeleteAccountConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    UserProfile userProfile,
  ) {
    showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('アカウント削除'),
            content: const Text('本当にアカウントを削除しますか？この操作は元に戻せません。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('キャンセル'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () async {
                  try {
                    // Firebase認証からのサインアウト
                    await ref.read(authServiceProvider).signOut();
                  } on Exception catch (e) {
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('アカウント削除に失敗しました: $e')),
                      );
                    }
                  }
                },
                child: const Text('削除する'),
              ),
            ],
          ),
    );
  }
}
