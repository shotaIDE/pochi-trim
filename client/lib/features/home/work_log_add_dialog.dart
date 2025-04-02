import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/features/home/work_log_add_screen.dart';
import 'package:house_worker/models/work_log.dart';
import 'package:house_worker/repositories/work_log_repository.dart';
import 'package:house_worker/services/auth_service.dart';
import 'package:intl/intl.dart';

// ランダムな絵文字を生成するためのリスト
const _emojiList = <String>[
  '🧹',
  '🧼',
  '🧽',
  '🧺',
  '🛁',
  '🚿',
  '🚽',
  '🧻',
  '🧯',
  '🔥',
  '💧',
  '🌊',
  '🍽️',
  '🍴',
  '🥄',
  '🍳',
  '🥘',
  '🍲',
  '🥣',
  '🥗',
  '🧂',
  '🧊',
  '🧴',
  '🧷',
  '🧺',
  '🧹',
  '🧻',
  '🧼',
  '🧽',
  '🧾',
  '📱',
  '💻',
  '🖥️',
  '🖨️',
  '⌨️',
  '🖱️',
  '🧮',
  '📔',
  '📕',
  '📖',
  '📗',
  '📘',
  '📙',
  '📚',
  '📓',
  '📒',
  '📃',
  '📜',
  '📄',
  '📰',
];

// ランダムな絵文字を取得する関数
String getRandomEmoji() {
  final random = Random();
  return _emojiList[random.nextInt(_emojiList.length)];
}

// ハウスIDを提供するプロバイダーはwork_log_add_screenからインポート

/// 家事ログ追加ダイアログを表示する関数
///
/// [context] - ビルドコンテキスト
/// [ref] - WidgetRef
/// [existingWorkLog] - 既存の家事ログ（オプション）
///
/// 戻り値: 家事ログが追加された場合はtrue、そうでない場合はfalse
Future<bool?> showWorkLogAddDialog(
  BuildContext context,
  WidgetRef ref, {
  WorkLog? existingWorkLog,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => WorkLogAddDialog(existingWorkLog: existingWorkLog),
  );
}

class WorkLogAddDialog extends ConsumerStatefulWidget {
  const WorkLogAddDialog({super.key, this.existingWorkLog});

  // 既存のワークログから新しいワークログを作成するためのファクトリコンストラクタ
  factory WorkLogAddDialog.fromExistingWorkLog(WorkLog workLog) {
    return WorkLogAddDialog(existingWorkLog: workLog);
  }
  final WorkLog? existingWorkLog;

  @override
  ConsumerState<WorkLogAddDialog> createState() => _WorkLogAddDialogState();
}

class _WorkLogAddDialogState extends ConsumerState<WorkLogAddDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _iconController;

  late DateTime _completedAt;

  @override
  void initState() {
    super.initState();
    // 既存のワークログがある場合は、そのデータを初期値として設定
    if (widget.existingWorkLog != null) {
      _titleController = TextEditingController(
        text: widget.existingWorkLog!.title,
      );
      _iconController = TextEditingController(
        text: widget.existingWorkLog!.icon,
      );
      _completedAt = DateTime.now(); // 現在時刻を設定
    } else {
      _titleController = TextEditingController();
      // 新規作成時はランダムな絵文字を初期値として設定
      _iconController = TextEditingController(text: getRandomEmoji());
      _completedAt = DateTime.now();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authServiceProvider).currentUser;
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');

    return AlertDialog(
      title: Text(widget.existingWorkLog != null ? '家事ログを記録' : '家事ログ追加'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 家事の名前表示
              if (widget.existingWorkLog != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      Text(
                        widget.existingWorkLog!.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.existingWorkLog!.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                // 家事ログの名前入力欄
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: '家事ログの名前',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '家事ログの名前を入力してください';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 16),

              // 家事ログのアイコン入力欄
              if (widget.existingWorkLog == null)
                TextFormField(
                  controller: _iconController,
                  decoration: const InputDecoration(
                    labelText: '家事ログのアイコン',
                    border: OutlineInputBorder(),
                    hintText: '絵文字1文字を入力',
                  ),
                  maxLength: 1, // 1文字のみ入力可能
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'アイコンを入力してください';
                    }
                    return null;
                  },
                ),
              if (widget.existingWorkLog == null) const SizedBox(height: 16),

              // 家事ログの完了時刻入力欄
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('完了時刻'),
                subtitle: Text(dateFormat.format(_completedAt)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDateTime(context),
              ),
              const SizedBox(height: 16),

              // 家事ログの実行したユーザー表示
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('実行したユーザー'),
                subtitle: Text(currentUser?.displayName ?? 'ゲスト'),
                leading: const Icon(Icons.person),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(onPressed: _submitForm, child: const Text('登録する')),
      ],
    );
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _completedAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null && mounted) {
      // BuildContextをローカル変数に保存して、マウント状態を確認した後に使用
      final pickedTime = await showTimePicker(
        context: mounted ? context : throw StateError('Widget is not mounted'),
        initialTime: TimeOfDay.fromDateTime(_completedAt),
      );

      if (pickedTime != null && mounted) {
        setState(() {
          _completedAt = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final workLogRepository = ref.read(workLogRepositoryProvider);
      final currentUser = ref.read(authServiceProvider).currentUser;
      final houseId = ref.read(currentHouseIdProvider); // ハウスIDを取得

      if (currentUser == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('ユーザー情報が取得できませんでした')));
        return;
      }

      // 既存のワークログを元にした場合でも、常に新規ワークログとして登録するためIDは空文字列を指定
      final workLog = WorkLog(
        id: '', // 常に新規ワークログとして登録するため空文字列を指定
        title: widget.existingWorkLog?.title ?? _titleController.text,
        icon: widget.existingWorkLog?.icon ?? _iconController.text, // アイコンを設定
        createdAt: DateTime.now(),
        completedAt: _completedAt,
        createdBy: currentUser.uid,
        completedBy: currentUser.uid,
        isShared: true, // デフォルトで共有
        isRecurring: false, // 家事ログは繰り返しなし
        isCompleted: true, // 家事ログは完了済み
      );

      try {
        // ワークログを保存（houseIdを指定）
        workLogRepository.save(houseId, workLog);

        // 保存成功メッセージを表示
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('家事ログを登録しました')));

          // ダイアログを閉じて更新フラグをtrueで返す
          Navigator.of(context).pop(true);
        }
      } on FirebaseException catch (e) {
        // エラー時の処理
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('エラーが発生しました: $e')));
        }
      }
    }
  }
}
