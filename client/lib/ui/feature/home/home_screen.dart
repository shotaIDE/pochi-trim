import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/data/model/clear_count_exception.dart';
import 'package:house_worker/data/model/count.dart';
import 'package:house_worker/data/model/count_up_exception.dart';
import 'package:house_worker/ui/feature/home/home_presenter.dart';
import 'package:house_worker/ui/feature/settings/settings_screen.dart';
import 'package:skeletonizer/skeletonizer.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  static const name = 'HomeScreen';

  static MaterialPageRoute<HomeScreen> route() => MaterialPageRoute<HomeScreen>(
    builder: (_) => const HomeScreen(),
    settings: const RouteSettings(name: name),
  );

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    const title = Text('カウンター');

    final settingsButton = IconButton(
      onPressed: () {
        Navigator.of(context).push(SettingsScreen.route());
      },
      tooltip: '設定を表示する',
      icon: const Icon(Icons.settings),
    );

    final countUpButton = FloatingActionButton(
      tooltip: 'カウントを増やす',
      onPressed: _clearCount,
      child: const Icon(Icons.add),
    );

    final clearButton = FloatingActionButton(
      tooltip: 'カウントをリセットする',
      onPressed: _countUp,
      child: const Icon(Icons.clear),
    );

    const body = Center(
      child: Padding(padding: EdgeInsets.all(16), child: _CounterPanel()),
    );

    return Scaffold(
      appBar: AppBar(title: title, actions: [settingsButton]),
      body: body,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [countUpButton, clearButton],
      ),
    );
  }

  Future<void> _countUp() async {
    await HapticFeedback.mediumImpact();

    try {
      await ref.read(countUpResultProvider.future);
    } on CountUpException {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('カウントの増加に失敗しました。しばらくしてから再度お試しください')),
      );
      return;
    }
  }

  Future<void> _clearCount() async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            content: const Text('カウンターをリセットしてもよろしいですか？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('削除'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('キャンセル'),
              ),
            ],
          ),
    );

    if (shouldClear != true) {
      return;
    }

    try {
      await ref.read(clearCountResultProvider.future);
    } on ClearCountException {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('カウントのリセットに失敗しました。しばらくしてから再度お試しください')),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('カウントをリセットしました。')));
  }
}

class _CounterPanel extends ConsumerWidget {
  const _CounterPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countFuture = ref.watch(currentCountProvider.future);

    return FutureBuilder(
      future: countFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('カウンターの値の取得に失敗しました。しばらくしてから再度アプリを起動してください。');
        }

        final count = snapshot.data;
        if (count == null) {
          return Skeletonizer(
            child: _CounterTextList(
              count: Count(id: '', value: 0, updatedAt: DateTime.now()),
            ),
          );
        }

        return _CounterTextList(count: count);
      },
    );
  }
}

class _CounterTextList extends StatelessWidget {
  const _CounterTextList({required this.count});

  final Count count;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 16,
      children: [
        Text(
          count.value.toString(),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        Text(
          '最終更新日時: ${count.updatedAt}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ],
    );
  }
}
