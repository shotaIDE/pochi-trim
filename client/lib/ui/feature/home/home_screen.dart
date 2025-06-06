import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pochi_trim/data/model/house_work.dart';
import 'package:pochi_trim/data/service/system_service.dart';
import 'package:pochi_trim/data/service/work_log_service.dart';
import 'package:pochi_trim/ui/feature/analysis/analysis_screen.dart';
import 'package:pochi_trim/ui/feature/home/add_house_work_screen.dart';
import 'package:pochi_trim/ui/feature/home/home_presenter.dart';
import 'package:pochi_trim/ui/feature/home/house_works_tab.dart';
import 'package:pochi_trim/ui/feature/home/work_log_included_house_work.dart';
import 'package:pochi_trim/ui/feature/home/work_logs_tab.dart';
import 'package:pochi_trim/ui/feature/settings/settings_screen.dart';
import 'package:skeletonizer/skeletonizer.dart';

// 選択されたタブを管理するプロバイダー
final selectedTabProvider = StateProvider<int>((ref) => 0);

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
  var _isLogTabHighlighted = false;

  @override
  Widget build(BuildContext context) {
    final selectedTab = ref.watch(selectedTabProvider);

    const titleText = Text('記録');

    final analysisButton = IconButton(
      onPressed: () {
        Navigator.of(context).push(AnalysisScreen.route());
      },
      tooltip: '分析を表示する',
      icon: const Icon(Icons.analytics),
    );
    final settingsButton = IconButton(
      onPressed: () {
        Navigator.of(context).push(SettingsScreen.route());
      },
      tooltip: '設定を表示する',
      icon: const Icon(Icons.settings),
    );

    const homeWorksTabItem = Tooltip(
      message: '登録されている家事を表示する',
      child: Tab(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 8,
          children: [Icon(Icons.list_alt), Text('家事')],
        ),
      ),
    );
    final workLogsTabItem = Tooltip(
      message: '完了した家事ログを表示する',
      child: AnimatedContainer(
        // TODO(ide): 文字サイズが変わった時にも固定サイズで問題ないか？
        padding: const EdgeInsets.symmetric(vertical: 12),
        duration: const Duration(milliseconds: 250),
        color: _isLogTabHighlighted
            ? Theme.of(context).highlightColor
            : Colors.transparent,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 8,
          children: [Icon(Icons.check_circle), Text('ログ')],
        ),
      ),
    );
    final tabBar = TabBar(
      onTap: (index) {
        ref.read(selectedTabProvider.notifier).state = index;
      },
      tabs: [homeWorksTabItem, workLogsTabItem],
    );

    final addHouseWorkButton = FloatingActionButton(
      tooltip: '家事を追加する',
      onPressed: () {
        Navigator.of(context).push(AddHouseWorkScreen.route());
      },
      child: const Icon(Icons.add),
    );

    return DefaultTabController(
      length: 2,
      initialIndex: selectedTab,
      child: Scaffold(
        appBar: AppBar(
          title: titleText,
          actions: [analysisButton, settingsButton],
          bottom: tabBar,
        ),
        body: TabBarView(
          children: [
            HouseWorksTab(onCompleteButtonTap: _onCompleteHouseWorkButtonTap),
            WorkLogsTab(onDuplicateButtonTap: _onDuplicateWorkLogButtonTap),
          ],
        ),
        floatingActionButton: addHouseWorkButton,
        bottomNavigationBar: _QuickRegisterBottomBar(
          onTap: _onQuickRegisterButtonPressed,
        ),
      ),
    );
  }

  Future<void> _onCompleteHouseWorkButtonTap(HouseWork houseWork) async {
    final result = await ref.read(
      onCompleteHouseWorkButtonTappedResultProvider(houseWork).future,
    );

    if (!mounted) {
      return;
    }

    if (!result) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('家事ログの記録に失敗しました。しばらくしてから再度お試しください')),
      );
      return;
    }

    _highlightWorkLogsTabItem();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('家事ログを記録しました')));
  }

  Future<void> _onDuplicateWorkLogButtonTap(
    WorkLogIncludedHouseWork workLogIncludedHouseWork,
  ) async {
    final isSucceeded = await ref.read(
      onDuplicateWorkLogButtonTappedResultProvider(
        workLogIncludedHouseWork,
      ).future,
    );

    if (!mounted) {
      return;
    }

    // TODO(ide): 共通化できる
    if (!isSucceeded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('家事ログの記録に失敗しました。しばらくしてから再度お試しください')),
      );
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('家事ログを記録しました')));
  }

  Future<void> _onQuickRegisterButtonPressed(HouseWork houseWork) async {
    final workLogService = ref.read(workLogServiceProvider);
    final systemService = ref.read(systemServiceProvider);

    final isSucceeded = await workLogService.recordWorkLog(
      houseWorkId: houseWork.id,
      onRequestAccepted: systemService.doHapticFeedbackActionReceived,
    );

    if (!mounted) {
      return;
    }

    // TODO(ide): 共通化
    if (!isSucceeded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('家事ログの記録に失敗しました。しばらくしてから再度お試しください')),
      );
      return;
    }

    final selectedTab = ref.read(selectedTabProvider);
    if (selectedTab == 0) {
      // 家事タブが選択されている場合は、ログタブの方に家事の登録が完了したことを通知する
      _highlightWorkLogsTabItem();
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('家事ログを記録しました')));
  }

  void _highlightWorkLogsTabItem() {
    setState(() {
      _isLogTabHighlighted = true;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isLogTabHighlighted = false;
        });
      }
    });
  }
}

class _QuickRegisterBottomBar extends ConsumerStatefulWidget {
  const _QuickRegisterBottomBar({required this.onTap});

  final void Function(HouseWork) onTap;

  @override
  ConsumerState<_QuickRegisterBottomBar> createState() =>
      _QuickRegisterBottomBarState();
}

class _QuickRegisterBottomBarState
    extends ConsumerState<_QuickRegisterBottomBar> {
  AsyncValue<List<HouseWork>> _sortedHouseWorksByCompletionCountAsync =
      const AsyncValue.loading();

  @override
  void initState() {
    super.initState();

    ref.listenManual(houseWorksSortedByMostFrequentlyUsedProvider, (
      previous,
      next,
    ) {
      // 2回以降にデータが取得された場合は、何もしない
      // UI上で頻繁に更新されてチラつくのを防ぐため
      if (!_sortedHouseWorksByCompletionCountAsync.isLoading) {
        return;
      }

      setState(() {
        _sortedHouseWorksByCompletionCountAsync = next;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 130),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(77), // 0.3 * 255 = 約77
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Skeletonizer(
          enabled: _sortedHouseWorksByCompletionCountAsync.isLoading,
          child: _sortedHouseWorksByCompletionCountAsync.when(
            data: (recentHouseWorks) {
              final items = recentHouseWorks.map((houseWork) {
                return _QuickRegisterButton(
                  houseWork: houseWork,
                  onTap: (houseWork) => widget.onTap(houseWork),
                );
              }).toList();

              return ListView(
                scrollDirection: Axis.horizontal,
                children: items,
              );
            },
            loading: () => ListView(
              scrollDirection: Axis.horizontal,
              children: List.filled(4, const _FakeQuickRegisterButton()),
            ),
            error: (_, _) => const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'クイック登録の取得に失敗しました。アプリを再起動し、再度お試しください。',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickRegisterButton extends ConsumerWidget {
  const _QuickRegisterButton({required this.houseWork, required this.onTap});

  final HouseWork houseWork;
  final void Function(HouseWork) onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: 100,
      child: InkWell(
        onTap: () => onTap(houseWork),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 4,
            children: [
              Container(
                alignment: Alignment.center,
                // TODO(ide): 共通化できる
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                width: 32,
                height: 32,
                child: Text(
                  houseWork.icon,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              Text(
                houseWork.title,
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FakeQuickRegisterButton extends StatelessWidget {
  const _FakeQuickRegisterButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            Container(
              alignment: Alignment.center,
              width: 32,
              height: 32,
              child: const Text('🙇🏻‍♂️', style: TextStyle(fontSize: 24)),
            ),
            const Text(
              'Fake house work',
              style: TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
