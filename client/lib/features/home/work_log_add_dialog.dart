import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/features/home/work_log_add_screen.dart';
import 'package:house_worker/models/house_work.dart';
import 'package:house_worker/models/work_log.dart';
import 'package:house_worker/repositories/house_work_repository.dart';
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

// 家事一覧を取得するプロバイダー
final StreamProviderFamily<HouseWork?, String> _houseWorkProvider =
    StreamProvider.family<HouseWork?, String>((ref, houseWorkId) {
      final houseWorkRepository = ref.read(houseWorkRepositoryProvider);
      final houseId = ref.read(currentHouseIdProvider);
      return houseWorkRepository.getById(
        houseId: houseId,
        houseWorkId: houseWorkId,
      );
    });

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
  required WorkLog existingWorkLog,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => WorkLogAddDialog(existingWorkLog: existingWorkLog),
  );
}

class WorkLogAddDialog extends ConsumerStatefulWidget {
  const WorkLogAddDialog({super.key, required this.existingWorkLog});

  // 既存のワークログから新しいワークログを作成するためのファクトリコンストラクタ
  factory WorkLogAddDialog.fromExistingWorkLog(WorkLog workLog) {
    return WorkLogAddDialog(existingWorkLog: workLog);
  }

  final WorkLog existingWorkLog;

  @override
  ConsumerState<WorkLogAddDialog> createState() => _WorkLogAddDialogState();
}

class _WorkLogAddDialogState extends ConsumerState<WorkLogAddDialog> {
  final _formKey = GlobalKey<FormState>();

  late String _selectedHouseWorkId;
  HouseWork? _selectedHouseWork;
  late DateTime _completedAt;

  @override
  void initState() {
    super.initState();
    // 既存のワークログのデータを初期値として設定（家事IDのみ）
    _selectedHouseWorkId = widget.existingWorkLog.houseWorkId;
    // 完了時刻は現在時刻を初期値として設定
    _completedAt = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authServiceProvider).currentUser;
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');
    final houseWorksAsync = ref.watch(_houseWorkProvider(_selectedHouseWorkId));

    return AlertDialog(
      title: const Text('家事ログを記録'),
      content: houseWorksAsync.when(
        data: (houseWork) {
          // 家事が選択されていない場合、最初の家事を選択
          if (houseWork != null) {
            _selectedHouseWorkId = houseWork.id;
            _selectedHouseWork = houseWork;
          } else {
            // TODO(ide): 家事が選択されていない場合の処理を追加
            throw StateError('家事データが見つかりません');
          }

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 選択された家事の詳細表示
                  if (_selectedHouseWork != null) ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Text(
                        _selectedHouseWork!.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(_selectedHouseWork!.title),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 完了時刻入力欄
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('完了時刻'),
                    subtitle: Text(dateFormat.format(_completedAt)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _selectDateTime(context),
                  ),
                  const SizedBox(height: 8),

                  // 実行ユーザー表示
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('実行したユーザー'),
                    subtitle: Text(currentUser?.displayName ?? 'ゲスト'),
                    leading: const Icon(Icons.person),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, stackTrace) =>
                Center(child: Text('家事データの読み込みに失敗しました: $error')),
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
      final houseId = ref.read(currentHouseIdProvider);

      if (currentUser == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('ユーザー情報が取得できませんでした')));
        return;
      }

      // 新しい家事ログを作成
      final workLog = WorkLog(
        id: '', // 常に新規家事ログとして登録するため空文字列を指定
        houseWorkId: _selectedHouseWorkId, // 選択された家事のID
        completedAt: _completedAt, // 完了時刻
        completedBy: currentUser.uid, // 実行ユーザー
      );

      try {
        // 家事ログを保存
        workLogRepository.save(houseId, workLog);

        // 保存成功メッセージを表示
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('家事ログを登録しました')));

          // ダイアログを閉じる（更新フラグをtrueにして渡す）
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
