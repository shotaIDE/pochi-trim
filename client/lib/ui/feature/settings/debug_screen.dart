import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pochi_trim/data/service/in_app_purchase_service.dart';
import 'package:pochi_trim/ui/feature/settings/debug_presenter.dart';
import 'package:pochi_trim/ui/feature/settings/section_header.dart';
import 'package:skeletonizer/skeletonizer.dart';

class DebugScreen extends ConsumerWidget {
  const DebugScreen({super.key});

  static const name = 'DebugScreen';

  static MaterialPageRoute<DebugScreen> route() =>
      MaterialPageRoute<DebugScreen>(
        builder: (_) => const DebugScreen(),
        settings: const RouteSettings(name: name),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('デバッグ')),
      body: ListView(
        children: [
          const SectionHeader(title: 'RevenueCat'),
          const _ToggleIsProTile(),
          const SectionHeader(title: 'チュートリアル'),
          _ResetReviewStatusTile(
            keyDisplayName: '家事ログ登録のチュートリアル',
            onReset: () => ref.read(
              resetHowToRegisterWorkLogsTutorialStatusProvider.future,
            ),
          ),
          _ResetReviewStatusTile(
            keyDisplayName: '家事ログと分析の確認のチュートリアル',
            onReset: () => ref.read(
              resetHowToCheckWorkLogsAndAnalysisTutorialStatusProvider.future,
            ),
          ),
          const SectionHeader(title: 'アプリ内レビュー'),
          _ResetReviewStatusTile(
            keyDisplayName: '家事ログ30回完了のフラグ',
            onReset: () =>
                ref.read(reset30WorkLogsReviewRequestStatusProvider.future),
          ),
          _ResetReviewStatusTile(
            keyDisplayName: '家事ログ100回完了のフラグ',
            onReset: () =>
                ref.read(reset100WorkLogsReviewRequestStatusProvider.future),
          ),
          _ResetReviewStatusTile(
            keyDisplayName: '初めて分析したフラグ',
            onReset: () =>
                ref.read(resetAnalysisReviewRequestStatusProvider.future),
          ),
          _ResetReviewStatusTile(
            keyDisplayName: '家事ログ完了回数',
            onReset: () =>
                ref.read(resetWorkLogCountForAppReviewRequestProvider.future),
          ),
          const SectionHeader(title: 'Crashlytics'),
          const _ForceErrorTile(),
          const _ForceCrashTile(),
        ],
      ),
    );
  }
}

class _ForceCrashTile extends StatelessWidget {
  const _ForceCrashTile();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('強制クラッシュ'),
      onTap: () => FirebaseCrashlytics.instance.crash(),
    );
  }
}

class _ForceErrorTile extends StatelessWidget {
  const _ForceErrorTile();

  @override
  Widget build(BuildContext context) {
    return ListTile(title: const Text('強制エラー'), onTap: () => throw Exception());
  }
}

class _ToggleIsProTile extends ConsumerWidget {
  const _ToggleIsProTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isProFuture = ref.watch(isProUserProvider.future);

    return FutureBuilder(
      future: isProFuture,
      builder: (context, snapshot) {
        final isPro = snapshot.data;
        final String isProText;
        if (isPro == null) {
          isProText = '不明';
        } else {
          isProText = isPro ? 'Pro版' : 'フリー版';
        }

        return ListTile(
          title: const Text('Pro版有効状態をトグル'),
          trailing: Skeletonizer(
            enabled: isPro == null,
            child: Text(isProText),
          ),
          onTap: () {
            if (isPro == null) {
              return;
            }

            ref.read(isProUserProvider.notifier).setProUser(isPro: !isPro);
          },
        );
      },
    );
  }
}

class _ResetReviewStatusTile extends StatefulWidget {
  const _ResetReviewStatusTile({
    required this.keyDisplayName,
    required this.onReset,
  });

  final String keyDisplayName;
  final Future<void> Function() onReset;

  @override
  State<_ResetReviewStatusTile> createState() => _ResetReviewStatusTileState();
}

class _ResetReviewStatusTileState extends State<_ResetReviewStatusTile> {
  @override
  Widget build(BuildContext context) {
    final title = '${widget.keyDisplayName}をリセット';

    return ListTile(title: Text(title), onTap: _onTap);
  }

  Future<void> _onTap() async {
    await widget.onReset();

    if (!mounted) {
      return;
    }

    final message = '${widget.keyDisplayName}をリセットしました';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
