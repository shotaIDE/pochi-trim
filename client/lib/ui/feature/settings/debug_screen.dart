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
        children: const [
          SectionHeader(title: 'RevenueCat'),
          _ToggleIsProTile(),
          SectionHeader(title: 'レビュー'),
          _Reset30WorkLogsReviewStatusTile(),
          _Reset100WorkLogsReviewStatusTile(),
          _ResetAnalysisReviewStatusTile(),
          SectionHeader(title: 'Crashlytics'),
          _ForceErrorTile(),
          _ForceCrashTile(),
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

class _Reset30WorkLogsReviewStatusTile extends ConsumerWidget {
  const _Reset30WorkLogsReviewStatusTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      title: const Text('30回レビューリクエスト状態をリセット'),
      subtitle: const Text('30回目の家事ログ完了時のレビューを再度促すことができます'),
      onTap: () async {
        await ref.read(reset30WorkLogsReviewRequestStatusProvider.future);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('30回レビューリクエスト状態をリセットしました')),
          );
        }
      },
    );
  }
}

class _Reset100WorkLogsReviewStatusTile extends ConsumerWidget {
  const _Reset100WorkLogsReviewStatusTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      title: const Text('100回レビューリクエスト状態をリセット'),
      subtitle: const Text('100回目の家事ログ完了時のレビューを再度促すことができます'),
      onTap: () async {
        await ref.read(reset100WorkLogsReviewRequestStatusProvider.future);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('100回レビューリクエスト状態をリセットしました')),
          );
        }
      },
    );
  }
}

class _ResetAnalysisReviewStatusTile extends ConsumerWidget {
  const _ResetAnalysisReviewStatusTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      title: const Text('分析画面レビューリクエスト状態をリセット'),
      subtitle: const Text('分析画面表示後のレビューを再度促すことができます'),
      onTap: () async {
        await ref.read(resetAnalysisReviewRequestStatusProvider.future);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('分析画面レビューリクエスト状態をリセットしました')),
          );
        }
      },
    );
  }
}
