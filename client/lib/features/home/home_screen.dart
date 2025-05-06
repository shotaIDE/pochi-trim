import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/features/analysis/analysis_screen.dart';
import 'package:house_worker/features/home/home_presenter.dart';
import 'package:house_worker/features/home/house_works_tab.dart';
import 'package:house_worker/features/home/work_log_add_screen.dart';
import 'package:house_worker/features/home/work_logs_tab.dart';
import 'package:house_worker/features/settings/settings_screen.dart';
import 'package:house_worker/models/house_work.dart';
import 'package:house_worker/models/work_log.dart';
import 'package:house_worker/repositories/house_work_repository.dart';
import 'package:house_worker/services/auth_service.dart';
import 'package:house_worker/services/work_log_service.dart';
import 'package:skeletonizer/skeletonizer.dart';

// 選択されたタブを管理するプロバイダー
final selectedTabProvider = StateProvider<int>((ref) => 0);

// WorkLogに対応するHouseWorkを取得するプロバイダー
final FutureProviderFamily<HouseWork?, WorkLog> houseWorkForWorkLogProvider =
    FutureProvider.family<HouseWork?, WorkLog>((ref, workLog) {
      final houseWorkRepository = ref.watch(houseWorkRepositoryProvider);

      return houseWorkRepository.getByIdOnce(workLog.houseWorkId);
    });

// 家事をもとに新しいWorkLogを作成するための便利なプロバイダー
// TODO(ide): これが本当に必要か確認
final ProviderFamily<WorkLog, HouseWork> workLogForHouseWorkProvider =
    Provider.family<WorkLog, HouseWork>((ref, houseWork) {
      return WorkLog(
        id: '',
        houseWorkId: houseWork.id,
        completedAt: DateTime.now(),
        completedBy: ref.read(authServiceProvider).currentUser?.uid ?? '',
      );
    });

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

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
      icon: const Icon(Icons.analytics),
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (context) => const AnalysisScreen()),
        );
      },
    );
    final settingsButton = IconButton(
      icon: const Icon(Icons.settings),
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (context) => const SettingsScreen()),
        );
      },
    );

    const homeWorksTabItem = Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 8,
        children: [Icon(Icons.list_alt), Text('家事')],
      ),
    );
    final workLogsTabItem = AnimatedContainer(
      // TODO(ide): 文字サイズが変わった時にも固定サイズで問題ないか？
      padding: const EdgeInsets.symmetric(vertical: 12),
      duration: const Duration(milliseconds: 250),
      color:
          _isLogTabHighlighted
              ? Theme.of(context).highlightColor
              : Colors.transparent,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 8,
        children: [Icon(Icons.check_circle), Text('ログ')],
      ),
    );
    final tabBar = TabBar(
      onTap: (index) {
        ref.read(selectedTabProvider.notifier).state = index;
      },
      tabs: [homeWorksTabItem, workLogsTabItem],
    );

    final addHouseWorkButton = FloatingActionButton(
      tooltip: '家事を追加',
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute<bool?>(
            builder: (context) => const HouseWorkAddScreen(),
          ),
        );
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
            HouseWorksTab(onHouseWorkCompleted: _highlightWorkLogsTabItem),
            const WorkLogsTab(),
          ],
        ),
        floatingActionButton: addHouseWorkButton,
        bottomNavigationBar: _QuickRegisterBottomBar(
          onTap: _onQuickRegisterButtonPressed,
        ),
      ),
    );
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

  Future<void> _onQuickRegisterButtonPressed(HouseWork houseWork) async {
    await HapticFeedback.mediumImpact();

    final workLogService = ref.read(workLogServiceProvider);

    final isSucceeded = await workLogService.recordWorkLog(
      houseWorkId: houseWork.id,
    );

    if (!mounted) {
      return;
    }

    // TODO(ide): 共通化
    if (!isSucceeded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('家事の登録に失敗しました。しばらくしてから再度お試しください')),
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
    ).showSnackBar(const SnackBar(content: Text('家事を登録しました')));
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
              final items =
                  recentHouseWorks.map((houseWork) {
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
            loading:
                () => ListView(
                  scrollDirection: Axis.horizontal,
                  children: List.filled(4, const _FakeQuickRegisterButton()),
                ),
            error:
                (_, _) => const Center(
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
