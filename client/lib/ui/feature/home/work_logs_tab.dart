import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pochi_trim/data/model/add_work_log_exception.dart';
import 'package:pochi_trim/data/model/delete_work_log_exception.dart';
import 'package:pochi_trim/data/model/house_work.dart';
import 'package:pochi_trim/data/model/update_work_log_exception.dart';
import 'package:pochi_trim/data/model/work_log.dart';
import 'package:pochi_trim/data/repository/dao/add_work_log_args.dart';
import 'package:pochi_trim/data/repository/work_log_repository.dart';
import 'package:pochi_trim/ui/feature/home/edit_work_log_presenter.dart';
import 'package:pochi_trim/ui/feature/home/work_log_included_house_work.dart';
import 'package:pochi_trim/ui/feature/home/work_log_item.dart';
import 'package:pochi_trim/ui/feature/home/work_log_modal_bottom_sheet.dart';
import 'package:pochi_trim/ui/feature/home/work_logs_presenter.dart';
import 'package:skeletonizer/skeletonizer.dart';

// 完了した家事ログ一覧のタブ
class WorkLogsTab extends ConsumerStatefulWidget {
  const WorkLogsTab({
    super.key,
    required this.onDuplicateButtonTap,
    this.firstWorkLogKey,
  });

  final void Function(WorkLogIncludedHouseWork) onDuplicateButtonTap;
  final GlobalKey<State<StatefulWidget>>? firstWorkLogKey;

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
              ),
              completedAt: DateTime.now(),
              completedBy: 'dummyUser',
            ),
            onDuplicate: (_) {},
            onDelete: (_) {},
            onLongPress: (_) {},
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
            return _buildAnimatedItem(context, workLog, animation, index);
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
    int index,
  ) {
    final isFirstItem = index == 0;

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
            key: isFirstItem ? widget.firstWorkLogKey : null,
            workLogIncludedHouseWork: workLogIncludedHouseWork,
            onDuplicate: widget.onDuplicateButtonTap,
            onDelete: _onDelete,
            onLongPress: _onLongPress,
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
          index,
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
    final workLogRepository = ref.read(workLogRepositoryProvider);
    final workLog = workLogIncludedHouseWork.toWorkLog();

    try {
      await workLogRepository.delete(workLog.id);
    } on DeleteWorkLogException {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('家事ログの削除に失敗しました。しばらくしてから再度お試しください')),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          spacing: 12,
          children: [
            Icon(Icons.delete, color: Theme.of(context).colorScheme.surface),
            const Expanded(child: Text('家事ログを削除しました。')),
          ],
        ),
        action: SnackBarAction(
          label: '元に戻す',
          onPressed: () => _undoDelete(workLog),
        ),
      ),
    );
  }

  Future<void> _onLongPress(
    WorkLogIncludedHouseWork workLogIncludedHouseWork,
  ) async {
    final action = await showWorkLogActionModalBottomSheet(context);
    if (action == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    switch (action) {
      case WorkLogAction.edit:
        await _editWorkLog(workLogIncludedHouseWork);
      case WorkLogAction.delete:
        await _onDelete(workLogIncludedHouseWork);
    }
  }

  Future<void> _undoDelete(WorkLog workLog) async {
    final workLogRepository = ref.read(workLogRepositoryProvider);

    final addWorkLogArgs = AddWorkLogArgs.fromWorkLog(workLog);

    try {
      await workLogRepository.add(addWorkLogArgs);
    } on AddWorkLogException {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('家事ログの復元に失敗しました')));
      return;
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('家事ログを元に戻しました。')));
  }

  Future<void> _editWorkLog(
    WorkLogIncludedHouseWork workLogIncludedHouseWork,
  ) async {
    final newCompletedAt = await showDialog<DateTime>(
      context: context,
      builder: (context) => _EditWorkLogDialog(
        workLogIncludedHouseWork: workLogIncludedHouseWork,
      ),
    );

    if (newCompletedAt == null) {
      return;
    }

    try {
      await ref.read(
        updateCompletedAtOfWorkLogProvider(
          workLogIncludedHouseWork.id,
          newCompletedAt,
        ).future,
      );
    } on UpdateWorkLogException catch (e) {
      if (!mounted) {
        return;
      }

      final message = switch (e) {
        UpdateWorkLogExceptionFutureDateTime() => '未来の日時は設定できません',
        UpdateWorkLogExceptionUncategorized() =>
          '家事ログの更新に失敗しました。しばらくしてから再度お試しください',
      };

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('家事ログの日時を更新しました')),
    );
  }
}

class _EditWorkLogDialog extends ConsumerStatefulWidget {
  const _EditWorkLogDialog({
    required this.workLogIncludedHouseWork,
  });

  final WorkLogIncludedHouseWork workLogIncludedHouseWork;

  @override
  ConsumerState<_EditWorkLogDialog> createState() => _EditWorkLogDialogState();
}

class _EditWorkLogDialogState extends ConsumerState<_EditWorkLogDialog> {
  late DateTime _selectedDateTime;

  @override
  void initState() {
    super.initState();

    _selectedDateTime = widget.workLogIncludedHouseWork.completedAt;
  }

  @override
  Widget build(BuildContext context) {
    final houseWork = widget.workLogIncludedHouseWork.houseWork;

    return AlertDialog(
      title: Row(
        spacing: 12,
        children: [
          Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            width: 32,
            height: 32,
            child: Text(
              houseWork.icon,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Expanded(
            child: Text(
              houseWork.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('日付'),
            subtitle: Text(
              DateFormat('yyyy/MM/dd (E)', 'ja').format(_selectedDateTime),
            ),
            onTap: _selectDate,
          ),
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('時刻'),
            subtitle: Text(
              DateFormat('HH:mm').format(_selectedDateTime),
            ),
            onTap: _selectTime,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_selectedDateTime),
          child: const Text('保存'),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('ja', 'JP'),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _selectedDateTime = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _selectedDateTime.hour,
        _selectedDateTime.minute,
      );
    });
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _selectedDateTime = DateTime(
        _selectedDateTime.year,
        _selectedDateTime.month,
        _selectedDateTime.day,
        picked.hour,
        picked.minute,
      );
    });
  }
}
