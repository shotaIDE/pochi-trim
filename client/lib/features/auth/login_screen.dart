import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      icon: const Icon(Icons.login),
      label: const Text('Googleアカウントで開始'),
      onPressed: _startWithGoogle,
    );

    final continueWithoutAccountButton = TextButton(
      onPressed: _startWithoutAccount,
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

  Future<void> _startWithoutAccount() async {
    try {
      await ref.read(startResultProvider.notifier).startWithoutAccount();
    } on SignInException {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ログインに失敗しました。しばらくしてから再度お試しください。')),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    await Navigator.of(context).pushReplacement(HomeScreen.route());
  }

  Future<void> _startWithGoogle() async {
    try {
      await ref.read(startResultProvider.notifier).startWithGoogle();
    } on SignInException {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ログインに失敗しました。しばらくしてから再度お試しください。')),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    await Navigator.of(context).pushReplacement(HomeScreen.route());
  }
}
