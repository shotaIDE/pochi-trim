import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pochi_trim/data/definition/app_definition.dart';
import 'package:pochi_trim/data/model/generate_my_house_exception.dart';
import 'package:pochi_trim/data/model/sign_in_result.dart';
import 'package:pochi_trim/ui/component/color.dart';
import 'package:pochi_trim/ui/feature/auth/login_presenter.dart';
import 'package:pochi_trim/ui/feature/home/home_screen.dart';
import 'package:url_launcher/url_launcher.dart';

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

    final termsOfServiceButton = TextButton(
      onPressed: isLoading ? null : () => launchUrl(termsOfServiceUri),
      child: const Text('利用規約'),
    );
    final privacyPolicyButton = TextButton(
      onPressed: isLoading ? null : () => launchUrl(privacyPolicyUrl),
      child: const Text('プライバシーポリシー'),
    );
    final openUrlsPanel = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 16,
      children: [
        termsOfServiceButton,

        privacyPolicyButton,
      ],
    );

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

    const continueWithoutAccountText = Text('アカウントを利用せず続ける');
    final continueWithoutAccountButton = TextButton(
      onPressed: isLoading ? null : _startWithoutAccount,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
      ),
      child: loginStatus == LoginStatus.signingInAnonymously
          ? const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _LoadingIndicatorReplacingButtonIcon(
                  semanticsLabel: 'ゲストユーザーとしてログインしています',
                ),
                SizedBox(width: 8),
                continueWithoutAccountText,
              ],
            )
          : continueWithoutAccountText,
    );

    final children = <Widget>[
      Text('ぽちそぎ', style: Theme.of(context).textTheme.headlineLarge),
      const SizedBox(height: 20),
      Text(
        '過剰な家事を「そぎ落とし」\nやりたいことに集中しましょう',
        style: Theme.of(context).textTheme.bodyLarge,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 32),
      openUrlsPanel,
      const SizedBox(height: 16),
      startWithGoogleButton,
      const SizedBox(height: 16),
      if (Platform.isIOS) ...[startWithAppleButton, const SizedBox(height: 16)],
      continueWithoutAccountButton,
    ];

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

    if (!mounted) {
      return;
    }

    await Navigator.of(context).pushReplacement(HomeScreen.route());
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

    if (!mounted) {
      return;
    }

    await Navigator.of(context).pushReplacement(HomeScreen.route());
  }

  Future<void> _startWithoutAccount() async {
    try {
      await ref.read(currentLoginStatusProvider.notifier).startWithoutAccount();
    } on GenerateMyHouseException {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(_failedLoginSnackBar);
      return;
    } on SignInAnonymouslyException {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(_failedLoginSnackBar);
      return;
    }

    if (!mounted) {
      return;
    }

    await Navigator.of(context).pushReplacement(HomeScreen.route());
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
