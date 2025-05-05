import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/features/analysis/analysis_screen.dart';
import 'package:house_worker/features/home/home_presenter.dart';
import 'package:house_worker/features/home/house_work_list_tab.dart';
import 'package:house_worker/features/home/work_log_add_screen.dart';
import 'package:house_worker/features/home/work_log_dashboard_screen.dart';
import 'package:house_worker/features/home/work_log_included_house_work.dart';
import 'package:house_worker/features/home/work_log_item.dart';
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

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 選択されているタブを取得
    final selectedTab = ref.watch(selectedTabProvider);

    return DefaultTabController(
      length: 2,
      initialIndex: selectedTab,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('家事ログ'),
          actions: [
            IconButton(
              icon: const Icon(Icons.analytics),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const AnalysisScreen(),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
          ],
          bottom: TabBar(
            onTap: (index) {
              ref.read(selectedTabProvider.notifier).state = index;
            },
            tabs: const [
              Tab(icon: Icon(Icons.home_work), text: '家事一覧'),
              Tab(icon: Icon(Icons.task_alt), text: '完了家事'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // 家事一覧タブ
            const HouseWorkListTab(),
            // 完了した家事ログ一覧のタブ
            _CompletedWorkLogsTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // 家事追加画面に直接遷移
            Navigator.of(context).push(
              MaterialPageRoute<bool?>(
                builder: (context) => const HouseWorkAddScreen(),
              ),
            );
          },
          child: const Icon(Icons.add),
        ),
        bottomNavigationBar: const _QuickRegisterBottomBar(),
      ),
    );
  }
}

// 完了した家事ログ一覧のタブ
class _CompletedWorkLogsTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CompletedWorkLogsTab> createState() =>
      _CompletedWorkLogsTabState();
}

class _CompletedWorkLogsTabState extends ConsumerState<_CompletedWorkLogsTab> {
  final _listKey = GlobalKey<AnimatedListState>();
  List<WorkLogIncludedHouseWork> _currentWorkLogs = [];

  @override
  void initState() {
    super.initState();

    ref.listenManual(workLogsIncludedHouseWorkProvider, (_, next) {
      next.maybeWhen(data: _handleListChanges, orElse: () {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final workLogsIncludedHouseWorkFuture = ref.watch(
      workLogsIncludedHouseWorkProvider.future,
    );

    return FutureBuilder(
      future: workLogsIncludedHouseWorkFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('エラーが発生しました: ${snapshot.error}'));
        }

        final workLogs = snapshot.data;
        if (workLogs == null) {
          final dummyHouseWorkItem = WorkLogItem(
            workLogIncludedHouseWork: WorkLogIncludedHouseWork(
              id: 'dummyId',
              houseWork: HouseWork(
                id: 'dummyHouseWorkId',
                title: 'Dummy House Work',
                icon: '🏠',
                createdAt: DateTime.now(),
                createdBy: 'DummyUser',
                isRecurring: false,
              ),
              completedAt: DateTime.now(),
              completedBy: 'dummyUser',
            ),
            onTap: () {},
            onComplete: () {},
          );

          return Skeletonizer(
            child: ListView.separated(
              itemCount: 10,
              itemBuilder: (context, index) => dummyHouseWorkItem,
              separatorBuilder: (_, _) => const Divider(),
            ),
          );
        }

        if (workLogs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.task_alt, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  '完了した家事ログはありません',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  '家事を完了すると、ここに表示されます',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return AnimatedList(
          key: _listKey,
          itemBuilder: (context, index, animation) {
            final workLog = _currentWorkLogs[index];
            return _buildAnimatedItem(context, workLog, animation);
          },
          initialItemCount: _currentWorkLogs.length,
        );
      },
    );
  }

  Widget _buildAnimatedItem(
    BuildContext context,
    WorkLogIncludedHouseWork workLogIncludedHouseWork,
    Animation<double> animation,
  ) {
    return SizeTransition(
      sizeFactor: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -1),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutQuart),
        ),
        child: FadeTransition(
          opacity: animation,
          child: WorkLogItem(
            workLogIncludedHouseWork: workLogIncludedHouseWork,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder:
                      (context) => WorkLogDashboardScreen(
                        workLog: workLogIncludedHouseWork.toWorkLog(),
                      ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // リスト変更を処理し、必要に応じてアニメーション
  void _handleListChanges(List<WorkLogIncludedHouseWork> newWorkLogs) {
    if (_currentWorkLogs.isEmpty) {
      setState(() {
        _currentWorkLogs = List.from(newWorkLogs);
      });
      return;
    }

    // 新しく追加されたアイテムを検出
    for (final newWorkLog in newWorkLogs) {
      final existingIndex = _currentWorkLogs.indexWhere(
        (log) => log.id == newWorkLog.id,
      );
      if (existingIndex == -1) {
        // 新しいログを追加してアニメーション
        _currentWorkLogs.insert(0, newWorkLog); // 最新のログを先頭に追加
        _listKey.currentState?.insertItem(0);
      }
    }

    // 削除されたアイテムを検出（必要に応じて）
    final toRemove = <WorkLogIncludedHouseWork>[];
    for (final existingLog in _currentWorkLogs) {
      if (!newWorkLogs.any((log) => log.id == existingLog.id)) {
        toRemove.add(existingLog);
      }
    }

    // 削除アニメーション（必要に応じて）
    for (final logToRemove in toRemove) {
      final index = _currentWorkLogs.indexOf(logToRemove);
      if (index != -1) {
        final removedItem = _currentWorkLogs.removeAt(index);
        _listKey.currentState?.removeItem(
          index,
          (context, animation) => _buildAnimatedItem(
            context,
            removedItem,
            animation.drive(Tween(begin: 1, end: 0)),
          ),
        );
      }
    }
  }
}

class _QuickRegisterBottomBar extends ConsumerStatefulWidget {
  const _QuickRegisterBottomBar();

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
                    return _QuickRegisterButton(houseWork: houseWork);
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
  const _QuickRegisterButton({required this.houseWork});

  final HouseWork houseWork;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: 100,
      child: InkWell(
        onTap: () async {
          await HapticFeedback.mediumImpact();

          final workLogService = ref.read(workLogServiceProvider);

          final isSucceeded = await workLogService.recordWorkLog(
            houseWorkId: houseWork.id,
          );

          if (!context.mounted) {
            return;
          }

          // TODO(ide): 共通化
          if (!isSucceeded) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('家事の登録に失敗しました。しばらくしてから再度お試しください')),
            );
            return;
          }

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('家事を登録しました')));
        },
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
                  style: const TextStyle(fontSize: 24),
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
