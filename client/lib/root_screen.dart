import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/features/auth/login_screen.dart';
import 'package:house_worker/features/home/home_screen.dart';
import 'package:house_worker/root_app_session.dart';
import 'package:house_worker/root_presenter.dart';

class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  @override
  void initState() {
    super.initState();

    ref.read(rootAppInitializedProvider.notifier).initialize();
  }

  @override
  Widget build(BuildContext context) {
    final rootAppSession = ref.watch(rootAppInitializedProvider);

    switch (rootAppSession) {
      case final AppSessionSignedIn _:
        return const HomeScreen();
      case AppSessionNotSignedIn _:
        return const LoginScreen();
      case AppSessionLoading _:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
  }
}
