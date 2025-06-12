import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pochi_trim/data/model/sign_in_result.dart';
import 'package:pochi_trim/ui/component/color.dart';
import 'package:pochi_trim/ui/feature/auth/login_presenter.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  static const name = 'LoginScreen';

  static MaterialPageRoute<LoginScreen> route() =>
      MaterialPageRoute<LoginScreen>(
        builder: (_) => const LoginScreen(),
        settings: const RouteSettings(name: name),
      );

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    final loginStatus = ref.watch(currentLoginStatusProvider);
    final isLoading = loginStatus != LoginStatus.none;

    const continueWithoutAccountText = Text('アカウントを利用せず続ける');

    final startWithGoogleButton = ElevatedButton.icon(
      onPressed: isLoading ? null : _startWithGoogle,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
      ),
      icon: loginStatus == LoginStatus.signingInWithGoogle
          ? const _LoadingIndicatorReplacingButtonIcon(
              semanticsLabel: 'Googleでログインしています',
            )
          : const Icon(FontAwesomeIcons.google),
      label: const Text('Googleで続ける'),
    );

    final startWithAppleButton = ElevatedButton.icon(
      onPressed: isLoading ? null : _startWithApple,
      style: ElevatedButton.styleFrom(
        backgroundColor: signInWithAppleBackgroundColor(context),
        foregroundColor: signInWithAppleForegroundColor(context),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
      ),
      icon: loginStatus == LoginStatus.signingInWithApple
          ? const _LoadingIndicatorReplacingButtonIcon(
              semanticsLabel: 'Appleでログインしています',
            )
          : const Icon(FontAwesomeIcons.apple),
      label: const Text('Appleで続ける'),
    );

    final continueWithoutAccountButton = TextButton(
      onPressed: isLoading ? null : _startWithoutAccount,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
      ),
      child: loginStatus == LoginStatus.signingInAnonymously
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _LoadingIndicatorReplacingButtonIcon(
                  semanticsLabel: 'ゲストユーザーとしてログインしています',
                ),
                const SizedBox(width: 8),
                continueWithoutAccountText,
              ],
            )
          : continueWithoutAccountText,
    );

    final children = <Widget>[
      const Text(
        'House Worker',
        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 20),
      const Text('家事を簡単に記録・管理できるアプリ', style: TextStyle(fontSize: 16)),
      const SizedBox(height: 60),
      startWithGoogleButton,
      const SizedBox(height: 16),
    ];

    if (Platform.isIOS) {
      children.addAll([startWithAppleButton, const SizedBox(height: 16)]);
    }

    children.add(continueWithoutAccountButton);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: children,
        ),
      ),
    );
  }

  Future<void> _startWithGoogle() async {
    try {
      await ref.read(currentLoginStatusProvider.notifier).startWithGoogle();
    } on SignInWithGoogleException catch (error) {
      if (!mounted) {
        return;
      }

      switch (error) {
        case SignInWithGoogleExceptionCancelled():
          return;
        case SignInWithGoogleExceptionUncategorized():
          ScaffoldMessenger.of(context).showSnackBar(_failedLoginSnackBar);
          return;
      }
    }

    // ホーム画面への遷移は RootApp で自動で行われる
  }

  Future<void> _startWithApple() async {
    try {
      await ref.read(currentLoginStatusProvider.notifier).startWithApple();
    } on SignInWithAppleException catch (error) {
      if (!mounted) {
        return;
      }

      switch (error) {
        case SignInWithAppleExceptionCancelled():
          return;
        case SignInWithAppleExceptionUncategorized():
          ScaffoldMessenger.of(context).showSnackBar(_failedLoginSnackBar);
          return;
      }
    }

    // ホーム画面への遷移は RootApp で自動で行われる
  }

  Future<void> _startWithoutAccount() async {
    await ref.read(currentLoginStatusProvider.notifier).startWithoutAccount();

    // ホーム画面への遷移は RootApp で自動で行われる
  }
}

class _LoadingIndicatorReplacingButtonIcon extends StatelessWidget {
  const _LoadingIndicatorReplacingButtonIcon({required this.semanticsLabel});

  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        semanticsLabel: semanticsLabel,
      ),
    );
  }
}

const _failedLoginSnackBar = SnackBar(
  content: Text('ログインに失敗しました。しばらくしてから再度お試しください。'),
);
