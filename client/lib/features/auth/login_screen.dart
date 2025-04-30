import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/features/auth/login_presenter.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  @override
  void initState() {
    super.initState();

    ref.listenManual(loginButtonTappedResultProvider, (previous, next) {
      next.maybeWhen(
        error: (_, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ログインに失敗しました。しばらくしてから再度お試しください。')),
          );
        },
        orElse: () {},
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'House Worker',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text('家事を簡単に記録・管理できるアプリ', style: TextStyle(fontSize: 16)),
            SizedBox(height: 60),
            _LoginButton(),
          ],
        ),
      ),
    );
  }
}

class _LoginButton extends ConsumerWidget {
  const _LoginButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        await ref
            .read(loginButtonTappedResultProvider.notifier)
            .onLoginTapped();
      },
      child: const Text('ゲストとしてログイン'),
    );
  }
}
