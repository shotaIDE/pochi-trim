import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/features/analysis/analysis_screen.dart';
import 'package:house_worker/features/home/work_log_add_screen.dart';
import 'package:house_worker/features/home/work_log_dashboard_screen.dart';
import 'package:house_worker/features/home/work_log_item.dart';
import 'package:house_worker/features/home/work_log_provider.dart';
import 'package:house_worker/features/settings/settings_screen.dart';
import 'package:house_worker/models/house_work.dart';
import 'package:house_worker/models/work_log.dart';
import 'package:house_worker/repositories/house_work_repository.dart';
import 'package:house_worker/repositories/work_log_repository.dart';
import 'package:house_worker/services/auth_service.dart';
import 'package:house_worker/services/house_id_provider.dart';
import 'package:house_worker/services/work_log_service.dart';

// 選択されたタブを管理するプロバイダー
final selectedTabProvider = StateProvider<int>((ref) => 0);

// 予定家事一覧を提供するプロバイダー
final plannedWorkLogsProvider = StreamProvider<List<WorkLog>>((ref) {
  final workLogRepository = ref.watch(workLogRepositoryProvider);
  final houseId = ref.watch(currentHouseIdProvider);
  return workLogRepository.getIncompleteWorkLogs(houseId);
});

// WorkLogに対応するHouseWorkを取得するプロバイダー
final FutureProviderFamily<HouseWork?, WorkLog> houseWorkForWorkLogProvider =
    FutureProvider.family<HouseWork?, WorkLog>((ref, workLog) {
      final houseWorkRepository = ref.watch(houseWorkRepositoryProvider);
      final houseId = ref.watch(currentHouseIdProvider);
      return houseWorkRepository.getByIdOnce(
        houseId: houseId,
        houseWorkId: workLog.houseWorkId,
      );
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
              Tab(icon: Icon(Icons.calendar_today), text: '予定家事'),
              Tab(icon: Icon(Icons.task_alt), text: '完了家事'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // これから行う予定家事一覧のタブ
            _PlannedWorkLogsTab(),
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
        bottomNavigationBar: const _ShortCutBottomBar(),
      ),
    );
  }
}

// これから行う予定家事一覧のタブ
class _PlannedWorkLogsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plannedWorkLogsAsync = ref.watch(plannedWorkLogsProvider);

    return plannedWorkLogsAsync.when(
      data: (workLogs) {
        if (workLogs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  '予定されている家事はありません',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  '家事を追加すると、ここに表示されます',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            // プロバイダーを更新して最新のデータを取得
            ref.invalidate(plannedWorkLogsProvider);
          },
          child: ListView.builder(
            itemCount: workLogs.length,
            itemBuilder: (context, index) {
              final workLog = workLogs[index];
              return WorkLogItem(
                workLog: workLog,
                onTap: () {
                  // 家事ダッシュボード画面に遷移
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder:
                          (context) => WorkLogDashboardScreen(workLog: workLog),
                    ),
                  );
                },
                onComplete: () async {
                  // 家事を完了としてマーク
                  final userId = ref.read(authServiceProvider).currentUser?.uid;
                  if (userId != null) {
                    final workLogRepository = ref.read<WorkLogRepository>(
                      workLogRepositoryProvider,
                    );
                    final houseId = ref.read(currentHouseIdProvider);
                    await workLogRepository.completeWorkLog(
                      houseId,
                      workLog,
                      userId,
                    );
                  }
                },
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (error, stackTrace) => Center(
            child: Text('エラーが発生しました: $error', textAlign: TextAlign.center),
          ),
    );
  }
}

// 完了した家事ログ一覧のタブ
class _CompletedWorkLogsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completedWorkLogsAsync = ref.watch(completedWorkLogsProvider);

    return completedWorkLogsAsync.when(
      data: (workLogs) {
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

        return RefreshIndicator(
          onRefresh: () async {
            // プロバイダーを更新して最新のデータを取得
            ref
              ..invalidate(completedWorkLogsProvider)
              ..invalidate(houseWorksSortedByMostFrequentlyUsedProvider);
          },
          child: ListView.builder(
            itemCount: workLogs.length,
            itemBuilder: (context, index) {
              final workLog = workLogs[index];
              return WorkLogItem(
                workLog: workLog,
                onTap: () {
                  // 家事ダッシュボード画面に遷移
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder:
                          (context) => WorkLogDashboardScreen(workLog: workLog),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (error, stackTrace) => Center(
            child: Text('エラーが発生しました: $error', textAlign: TextAlign.center),
          ),
    );
  }
}

class _ShortCutBottomBar extends ConsumerWidget {
  const _ShortCutBottomBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final houseWorksAsync = ref.watch(
      houseWorksSortedByMostFrequentlyUsedProvider,
    );
    final workLogService = ref.watch(workLogServiceProvider);

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
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            // 最近登録された家事一覧
            ...houseWorksAsync.when(
              data: (recentHouseWorks) {
                if (recentHouseWorks.isEmpty) {
                  return [const SizedBox.shrink()];
                }

                return recentHouseWorks.map((houseWork) {
                  return SizedBox(
                    width: 100,
                    child: InkWell(
                      onTap: () async {
                        // 共通サービスを使用して家事ログを記録
                        await workLogService.recordWorkLog(
                          context,
                          houseWork.id,
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 4,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 4,
                          children: [
                            Container(
                              alignment: Alignment.center,
                              // TODO(ide): 共通化できる
                              decoration: BoxDecoration(
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainer,
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
                }).toList();
              },
              loading:
                  () => [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: CircularProgressIndicator(),
                    ),
                  ],
              error: (_, _) => [const SizedBox.shrink()],
            ),
          ],
        ),
      ),
    );
  }
}
