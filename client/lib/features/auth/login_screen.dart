import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:house_worker/features/auth/login_presenter.dart';
import 'package:house_worker/features/home/home_screen.dart';
import 'package:house_worker/models/sign_in_result.dart';

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
      label: const Text('Googleアカウントで開始'),
    );

    final continueWithoutAccountButton = TextButton(
      onPressed: _startWithoutAccount,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
      ),
      child: const Text('アカウントを利用せず開始'),
    );

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'House Worker',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text('家事を簡単に記録・管理できるアプリ', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 60),
            startWithGoogleButton,
            const SizedBox(height: 16),
            continueWithoutAccountButton,
          ],
        ),
      ),
    );
  }

  Future<void> _startWithGoogle() async {
    try {
      await ref.read(startResultProvider.notifier).startWithGoogle();
    } on SignInException catch (error) {
      if (!mounted) {
        return;
      }

      switch (error) {
        case SignInExceptionCancelled():
          return;
        case SignInExceptionAlreadyInUse():
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('このGoogleアカウントは、既に利用されています。別のアカウントでお試しください。'),
            ),
          );
          return;
        case SignInExceptionUncategorized():
          ScaffoldMessenger.of(context).showSnackBar(_failedLoginSnackBar);
          return;
      }
    }

    if (!mounted) {
      return;
    }

    await Navigator.of(context).pushReplacement(HomeScreen.route());
  }

  Future<void> _startWithoutAccount() async {
    await ref.read(startResultProvider.notifier).startWithoutAccount();

    if (!mounted) {
      return;
    }

    await Navigator.of(context).pushReplacement(HomeScreen.route());
  }
}

const _failedLoginSnackBar = SnackBar(
  content: Text('ログインに失敗しました。しばらくしてから再度お試しください。'),
);
