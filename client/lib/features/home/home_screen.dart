import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/features/home/work_log_add_dialog.dart';
import 'package:house_worker/features/home/work_log_add_screen.dart';
import 'package:house_worker/features/home/work_log_dashboard_screen.dart';
import 'package:house_worker/features/home/work_log_item.dart';
import 'package:house_worker/features/home/work_log_provider.dart';
import 'package:house_worker/features/settings/settings_screen.dart';
import 'package:house_worker/models/work_log.dart';
import 'package:house_worker/repositories/work_log_repository.dart';
import 'package:house_worker/services/auth_service.dart';

// 選択されたタブを管理するプロバイダー
final selectedTabProvider = StateProvider<int>((ref) => 0);

// 予定家事一覧を提供するプロバイダー
final plannedWorkLogsProvider = FutureProvider<List<WorkLog>>((ref) {
  final workLogRepository = ref.watch<WorkLogRepository>(
    workLogRepositoryProvider,
  );
  final houseId = ref.watch<String>(currentHouseIdProvider);
  return workLogRepository.getIncompleteWorkLogs(houseId);
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
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                ref.read(authServiceProvider).signOut();
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
            // 家事ログ追加の選択肢を表示するボトムシートを表示
            showModalBottomSheet<void>(
              context: context,
              builder:
                  (context) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.add_circle),
                        title: const Text('家事ログを画面で追加'),
                        onTap: () {
                          Navigator.pop(context); // ボトムシートを閉じる
                          // 既存のワークログ追加画面に遷移
                          Navigator.of(context)
                              .push(
                                MaterialPageRoute<bool?>(
                                  builder:
                                      (context) => const WorkLogAddScreen(),
                                ),
                              )
                              .then((updated) {
                                // 家事ログが追加された場合（updatedがtrue）、データを更新
                                if (updated ?? false) {
                                  ref
                                    ..invalidate(completedWorkLogsProvider)
                                    ..invalidate(
                                      frequentlyCompletedWorkLogsProvider,
                                    )
                                    ..invalidate(plannedWorkLogsProvider);
                                }
                              });
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.add_box),
                        title: const Text('家事ログをダイアログで追加'),
                        onTap: () {
                          Navigator.pop(context); // ボトムシートを閉じる
                          // 新しい家事ログ追加ダイアログを表示
                          showWorkLogAddDialog(context, ref).then((updated) {
                            // 家事ログが追加された場合（updatedがtrue）、データを更新
                            if (updated ?? false) {
                              ref
                                ..invalidate(completedWorkLogsProvider)
                                ..invalidate(
                                  frequentlyCompletedWorkLogsProvider,
                                )
                                ..invalidate(plannedWorkLogsProvider);
                            }
                          });
                        },
                      ),
                    ],
                  ),
            );
          },
          child: const Icon(Icons.add),
        ),
        bottomNavigationBar: _buildBottomShortcutBar(context, ref),
      ),
    );
  }

  Widget _buildBottomShortcutBar(BuildContext context, WidgetRef ref) {
    final frequentWorkLogsAsync = ref.watch(
      frequentlyCompletedWorkLogsProvider,
    );

    return frequentWorkLogsAsync.when(
      data: (frequentWorkLogs) {
        if (frequentWorkLogs.isEmpty) {
          return const SizedBox.shrink(); // 家事ログがない場合は表示しない
        }

        return Container(
          // TODO(ide): 高さを固定せず、内容に合わせて自動調整したい
          height: 90,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withAlpha(77), // 0.3 * 255 = 約77
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: frequentWorkLogs.length,
            itemBuilder: (context, index) {
              final workLog = frequentWorkLogs[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: InkWell(
                  onTap: () {
                    // ダイアログで家事ログを追加するか、画面で追加するかを選択するボトムシートを表示
                    showModalBottomSheet<void>(
                      context: context,
                      builder:
                          (context) => Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.add_circle),
                                title: const Text('家事ログを画面で記録'),
                                onTap: () {
                                  Navigator.pop(context); // ボトムシートを閉じる
                                  // 既存のワークログ追加画面に遷移
                                  Navigator.of(context)
                                      .push(
                                        MaterialPageRoute<bool?>(
                                          builder:
                                              (context) =>
                                                  WorkLogAddScreen.fromExistingWorkLog(
                                                    workLog,
                                                  ),
                                        ),
                                      )
                                      .then((updated) {
                                        // 家事ログが追加された場合（updatedがtrue）、データを更新
                                        if (updated == true) {
                                          ref
                                            ..invalidate(
                                              completedWorkLogsProvider,
                                            )
                                            ..invalidate(
                                              frequentlyCompletedWorkLogsProvider,
                                            )
                                            ..invalidate(
                                              plannedWorkLogsProvider,
                                            );
                                        }
                                      });
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.add_box),
                                title: const Text('家事ログをダイアログで記録'),
                                onTap: () {
                                  Navigator.pop(context); // ボトムシートを閉じる
                                  // 新しい家事ログ追加ダイアログを表示
                                  showWorkLogAddDialog(
                                    context,
                                    ref,
                                    existingWorkLog: workLog,
                                  ).then((updated) {
                                    // 家事ログが追加された場合（updatedがtrue）、データを更新
                                    if (updated == true) {
                                      ref
                                        ..invalidate(completedWorkLogsProvider)
                                        ..invalidate(
                                          frequentlyCompletedWorkLogsProvider,
                                        )
                                        ..invalidate(plannedWorkLogsProvider);
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // 内容に合わせてサイズを最小化
                      children: [
                        Text(
                          workLog.icon,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          workLog.title,
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
            },
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
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

                    // データを更新
                    ref
                      ..invalidate(completedWorkLogsProvider)
                      ..invalidate(frequentlyCompletedWorkLogsProvider)
                      ..invalidate(plannedWorkLogsProvider);
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
              ..invalidate(frequentlyCompletedWorkLogsProvider);
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
