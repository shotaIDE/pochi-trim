import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/services/auth_service.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            ElevatedButton(
              onPressed: () async {
                try {
                  await ref.read(authServiceProvider).signInAnonymously();
                } on FirebaseAuthException catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('ログインに失敗しました: $e')));
                  }
                }
              },
              child: const Text('ゲストとしてログイン'),
            ),
          ],
        ),
      ),
    );
  }
}
