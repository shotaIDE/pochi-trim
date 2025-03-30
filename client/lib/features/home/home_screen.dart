import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/features/home/work_log_add_screen.dart';
import 'package:house_worker/features/home/work_log_dashboard_screen.dart';
import 'package:house_worker/features/home/work_log_item.dart';
import 'package:house_worker/features/home/work_log_provider.dart';
import 'package:house_worker/features/settings/settings_screen.dart';
import 'package:house_worker/services/auth_service.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 完了済みワークログを取得
    final completedWorkLogsAsync = ref.watch(completedWorkLogsProvider);
    // よく完了されている家事ログを取得
    final frequentWorkLogsAsync = ref.watch(
      frequentlyCompletedWorkLogsProvider,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('家事ログ一覧'),
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
      ),
      body: Column(
        children: [
          Expanded(
            child: completedWorkLogsAsync.when(
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
                                  (context) =>
                                      WorkLogDashboardScreen(workLog: workLog),
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
                    child: Text(
                      'エラーが発生しました: $error',
                      textAlign: TextAlign.center,
                    ),
                  ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // ワークログ追加画面に遷移
          Navigator.of(context)
              .push(
                MaterialPageRoute<bool?>(
                  builder: (context) => const WorkLogAddScreen(),
                ),
              )
              .then((updated) {
                // 家事ログが追加された場合（updatedがtrue）、データを更新
                if (updated ?? false) {
                  ref
                    ..invalidate(completedWorkLogsProvider)
                    ..invalidate(frequentlyCompletedWorkLogsProvider);
                }
              });
        },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: frequentWorkLogsAsync.when(
        data: (frequentWorkLogs) {
          if (frequentWorkLogs.isEmpty) {
            return const SizedBox.shrink(); // 家事ログがない場合は表示しない
          }

          return Container(
            height: 60,
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
                      // 選択された家事ログを元に新しい家事ログを登録する画面に遷移
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
                                ..invalidate(completedWorkLogsProvider)
                                ..invalidate(
                                  frequentlyCompletedWorkLogsProvider,
                                );
                            }
                          });
                    },
                    child: Container(
                      width: 80,
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
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
                            maxLines: 1,
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
      ),
    );
  }
}
