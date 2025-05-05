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
        body: const TabBarView(children: [HouseWorksTab(), WorkLogsTab()]),
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
