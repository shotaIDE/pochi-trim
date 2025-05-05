import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/features/home/work_log_dashboard_screen.dart';
import 'package:house_worker/features/home/work_log_included_house_work.dart';
import 'package:house_worker/features/home/work_log_item.dart';
import 'package:house_worker/features/home/work_logs_presenter.dart';
import 'package:house_worker/models/house_work.dart';
import 'package:house_worker/services/work_log_service.dart';
import 'package:skeletonizer/skeletonizer.dart';

// 完了した家事ログ一覧のタブ
class WorkLogsTab extends ConsumerStatefulWidget {
  const WorkLogsTab({super.key});

  @override
  ConsumerState<WorkLogsTab> createState() => _WorkLogsTabState();
}

class _WorkLogsTabState extends ConsumerState<WorkLogsTab> {
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
            onLongPress: (_) {},
            onDuplicate: (_) {},
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
            onDuplicate: _onDuplicate,
            onLongPress: _onLongPress,
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

  Future<void> _onDuplicate(
    WorkLogIncludedHouseWork workLogIncludedHouseWork,
  ) async {
    // TODO(ide): ここでの処理は、Presenterに移動する
    await HapticFeedback.mediumImpact();

    final workLogService = ref.read(workLogServiceProvider);

    final isSucceeded = await workLogService.recordWorkLog(
      houseWorkId: workLogIncludedHouseWork.id,
    );

    if (!mounted) {
      return;
    }

    // TODO(ide): 共通化できる
    if (!isSucceeded) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('家事の記録に失敗しました。')));
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('家事を記録しました')));
  }

  Future<void> _onLongPress(
    WorkLogIncludedHouseWork workLogIncludedHouseWork,
  ) async {
    // TODO(ide): メニューを表示する
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder:
            (context) => WorkLogDashboardScreen(
              workLog: workLogIncludedHouseWork.toWorkLog(),
            ),
      ),
    );
  }
}
