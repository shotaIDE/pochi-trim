import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pochi_trim/data/model/house_work.dart';
import 'package:pochi_trim/ui/feature/home/work_log_included_house_work.dart';
import 'package:pochi_trim/ui/feature/home/work_log_item.dart';
import 'package:pochi_trim/ui/feature/home/work_log_provider.dart';
import 'package:pochi_trim/ui/feature/home/work_logs_presenter.dart';
import 'package:skeletonizer/skeletonizer.dart';

// 完了した家事ログ一覧のタブ
class WorkLogsTab extends ConsumerStatefulWidget {
  const WorkLogsTab({super.key, required this.onDuplicateButtonTap});

  final void Function(WorkLogIncludedHouseWork) onDuplicateButtonTap;

  @override
  ConsumerState<WorkLogsTab> createState() => _WorkLogsTabState();
}

class _WorkLogsTabState extends ConsumerState<WorkLogsTab> {
  final _listKey = GlobalKey<AnimatedListState>();
  List<WorkLogIncludedHouseWork> _currentWorkLogs = [];
  final _scrollController = ScrollController();

  // 無限スクロール用の設定
  var _isLoadingMore = false;
  var _usePagination = false;

  @override
  void initState() {
    super.initState();

    // スクロールリスナーを設定（無限スクロール用）
    _scrollController.addListener(_onScroll);

    // 初期データの読み込み完了後にページネーションモードに切り替え
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(workLogsPaginationProvider.notifier).loadInitial().then((_) {
        if (mounted) {
          setState(() {
            _usePagination = true;
          });
        }
      });
    });

    ref
      ..listenManual(workLogsIncludedHouseWorkProvider, (_, next) {
        if (!_usePagination) {
          next.maybeWhen(data: _handleListChanges, orElse: () {});
        }
      })
      // ページネーション対応のプロバイダーもリッスン
      ..listenManual(workLogsIncludedHouseWorkWithPaginationProvider, (
        _,
        next,
      ) {
        if (_usePagination) {
          next.maybeWhen(data: _handleListChanges, orElse: () {});
        }
      });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // スクロール監視（無限スクロール用）
  void _onScroll() {
    if (!_usePagination || _isLoadingMore) {
      return;
    }

    // 80%スクロールした時点で次のページを読み込み
    final threshold = _scrollController.position.maxScrollExtent * 0.8;
    if (_scrollController.position.pixels >= threshold) {
      _loadMoreData();
    }
  }

  // 追加データの読み込み
  Future<void> _loadMoreData() async {
    if (_isLoadingMore) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final paginationNotifier = ref.read(workLogsPaginationProvider.notifier);
      await paginationNotifier.loadMore();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ページネーションモードかどうかで使用するプロバイダーを切り替え
    final workLogsIncludedHouseWorkFuture = _usePagination
        ? ref.watch(workLogsIncludedHouseWorkWithPaginationProvider.future)
        : ref.watch(workLogsIncludedHouseWorkProvider.future);

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
              ),
              completedAt: DateTime.now(),
              completedBy: 'dummyUser',
            ),
            onDuplicate: (_) {},
            onDelete: (_) {},
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

        return RefreshIndicator(
          onRefresh: _onRefresh,
          child: Column(
            children: [
              Expanded(
                child: AnimatedList(
                  key: _listKey,
                  controller: _scrollController,
                  itemBuilder: (context, index, animation) {
                    final workLog = _currentWorkLogs[index];
                    return _buildAnimatedItem(context, workLog, animation);
                  },
                  initialItemCount: _currentWorkLogs.length,
                ),
              ),
              // ローディングインジケーター
              if (_isLoadingMore && _usePagination)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        );
      },
    );
  }

  // プルトゥリフレッシュ
  Future<void> _onRefresh() async {
    if (_usePagination) {
      final paginationNotifier = ref.read(workLogsPaginationProvider.notifier);
      await paginationNotifier.refresh();
    } else {
      // 通常のプロバイダーのリフレッシュ
      ref.invalidate(workLogsIncludedHouseWorkProvider);
    }
  }

  Widget _buildAnimatedItem(
    BuildContext context,
    WorkLogIncludedHouseWork workLogIncludedHouseWork,
    Animation<double> animation,
  ) {
    return SizeTransition(
      sizeFactor: animation,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
            .animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutQuart),
            ),
        child: FadeTransition(
          opacity: animation,
          child: WorkLogItem(
            workLogIncludedHouseWork: workLogIncludedHouseWork,
            onDuplicate: widget.onDuplicateButtonTap,
            onDelete: _onDelete,
          ),
        ),
      ),
    );
  }

  // リスト変更を処理し、必要に応じてアニメーション
  void _handleListChanges(List<WorkLogIncludedHouseWork> newWorkLogs) {
    // 初期化時は単純に置き換え
    if (_currentWorkLogs.isEmpty) {
      setState(() {
        _currentWorkLogs = List.from(newWorkLogs);
      });
      return;
    }

    // 削除されたアイテムを先に処理（インデックスの変更を避けるため逆順で処理）
    final toRemove = <int>[];
    for (var i = 0; i < _currentWorkLogs.length; i++) {
      final existingLog = _currentWorkLogs[i];
      if (!newWorkLogs.any((log) => log.id == existingLog.id)) {
        toRemove.add(i);
      }
    }

    // 削除アニメーション（逆順で処理してインデックスの問題を回避）
    for (final index in toRemove.reversed) {
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

    // 新しく追加されたアイテムを検出して追加
    for (var i = 0; i < newWorkLogs.length; i++) {
      final newWorkLog = newWorkLogs[i];
      final existingIndex = _currentWorkLogs.indexWhere(
        (log) => log.id == newWorkLog.id,
      );

      if (existingIndex == -1) {
        // シンプルに新しいデータの順序に従って挿入
        // _syncListOrderで最終的な順序調整を行う
        final insertIndex = i.clamp(0, _currentWorkLogs.length);

        _currentWorkLogs.insert(insertIndex, newWorkLog);
        _listKey.currentState?.insertItem(insertIndex);
      }
    }

    // 最終的に順序を同期（必要に応じて）
    _syncListOrder(newWorkLogs);
  }

  /// リストの順序を新しいデータと同期する
  ///
  /// [newWorkLogs] 新しい家事ログデータのリスト
  ///
  /// このメソッドは、_currentWorkLogsの順序がnewWorkLogsと一致しているかチェックし、
  /// 異なる場合はsetStateを使用してリストを再構築します。
  ///
  /// 使用タイミング:
  /// - _handleListChangesの最後で、追加・削除処理後の順序調整として呼び出す
  /// - アニメーション付きの個別追加・削除では順序が乱れる可能性があるため、
  ///   最終的な整合性を保つために必要
  void _syncListOrder(List<WorkLogIncludedHouseWork> newWorkLogs) {
    var needsReorder = false;

    // 順序が一致しているかチェック
    if (_currentWorkLogs.length == newWorkLogs.length) {
      for (var i = 0; i < _currentWorkLogs.length; i++) {
        if (_currentWorkLogs[i].id != newWorkLogs[i].id) {
          needsReorder = true;
          break;
        }
      }
    }

    // 順序が異なる場合は再構築
    if (needsReorder) {
      setState(() {
        _currentWorkLogs = List.from(newWorkLogs);
      });
    }
  }

  Future<void> _onDelete(
    WorkLogIncludedHouseWork workLogIncludedHouseWork,
  ) async {
    final workLogDeletion = ref.read(workLogDeletionProvider);

    await workLogDeletion.deleteWorkLog(workLogIncludedHouseWork.toWorkLog());

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.delete, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text('家事ログを削除しました')),
          ],
        ),
        action: SnackBarAction(
          label: '元に戻す',
          onPressed: () async {
            final workLogDeletion = ref.read(workLogDeletionProvider);
            await workLogDeletion.undoDelete();
          },
        ),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
