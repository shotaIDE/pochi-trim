import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:house_worker/data/model/sign_in_result.dart';
import 'package:house_worker/ui/component/color.dart';
import 'package:house_worker/ui/feature/auth/login_presenter.dart';

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
    final startWithGoogleButton = ElevatedButton.icon(
      onPressed: _startWithGoogle,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
      ),
      icon: const Icon(FontAwesomeIcons.google),
      label: const Text('Googleで続ける'),
    );

    final startWithAppleButton = ElevatedButton.icon(
      onPressed: _startWithApple,
      style: ElevatedButton.styleFrom(
        backgroundColor: signInWithAppleBackgroundColor(context),
        foregroundColor: signInWithAppleForegroundColor(context),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
      ),
      icon: const Icon(FontAwesomeIcons.apple),
      label: const Text('Appleで続ける'),
    );

    final continueWithoutAccountButton = TextButton(
      onPressed: _startWithoutAccount,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
      ),
      child: const Text('アカウントを利用せず続ける'),
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
      await ref.read(startResultProvider.notifier).startWithGoogle();
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
      await ref.read(startResultProvider.notifier).startWithApple();
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
    await ref.read(startResultProvider.notifier).startWithoutAccount();

    // ホーム画面への遷移は RootApp で自動で行われる
  }
}

const _failedLoginSnackBar = SnackBar(
  content: Text('ログインに失敗しました。しばらくしてから再度お試しください。'),
);
