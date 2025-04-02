import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

// ハウスIDを提供するプロバイダー（実際のアプリケーションに合わせて調整してください）
final currentHouseIdProvider = Provider<String>((ref) {
  // 実際のアプリケーションでは、ユーザーが選択したハウスIDを返すロジックを実装
  // 例: ユーザー設定から取得、状態管理から取得など
  return 'default-house-id'; // デフォルト値（実際の実装では適切な値に置き換えてください）
});

// 家事一覧を取得するプロバイダー
final FutureProviderFamily<List<HouseWork>, String> houseWorksProvider =
    FutureProvider.family<List<HouseWork>, String>((ref, houseId) {
      final houseWorkRepository = ref.read(houseWorkRepositoryProvider);
      return houseWorkRepository.getAll(houseId);
    });

class WorkLogAddScreen extends ConsumerStatefulWidget {
  const WorkLogAddScreen({super.key, this.existingWorkLog});

  // 既存のワークログから新しいワークログを作成するためのファクトリコンストラクタ
  factory WorkLogAddScreen.fromExistingWorkLog(WorkLog workLog) {
    return WorkLogAddScreen(existingWorkLog: workLog);
  }
  final WorkLog? existingWorkLog;

  @override
  ConsumerState<WorkLogAddScreen> createState() => _WorkLogAddScreenState();
}

class _WorkLogAddScreenState extends ConsumerState<WorkLogAddScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _noteController;

  String? _selectedHouseWorkId;
  HouseWork? _selectedHouseWork;
  late DateTime _completedAt;

  @override
  void initState() {
    super.initState();
    // 既存のワークログがある場合は、そのデータを初期値として設定
    if (widget.existingWorkLog != null) {
      _noteController = TextEditingController();
      _selectedHouseWorkId = widget.existingWorkLog!.houseWorkId;
      _completedAt = widget.existingWorkLog!.completedAt;
    } else {
      _noteController = TextEditingController();
      _completedAt = DateTime.now();
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authServiceProvider).currentUser;
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');
    final houseId = ref.watch(currentHouseIdProvider);
    final houseWorksAsync = ref.watch(houseWorksProvider(houseId));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingWorkLog != null ? '家事ログを記録' : '家事ログ追加'),
      ),
      body: houseWorksAsync.when(
        data: (houseWorks) {
          // 家事が選択されていない場合、最初の家事を選択
          if (_selectedHouseWorkId == null && houseWorks.isNotEmpty) {
            _selectedHouseWorkId = houseWorks.first.id;
            _selectedHouseWork = houseWorks.first;
          }

          // 選択された家事を特定
          if (_selectedHouseWork == null && _selectedHouseWorkId != null) {
            _selectedHouseWork = houseWorks.firstWhere(
              (hw) => hw.id == _selectedHouseWorkId,
              orElse: () => houseWorks.isNotEmpty ? houseWorks.first : null,
            );
          }

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 家事選択ドロップダウン
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: '家事を選択',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedHouseWorkId,
                    items:
                        houseWorks.map((houseWork) {
                          return DropdownMenuItem<String>(
                            value: houseWork.id,
                            child: Row(
                              children: [
                                Text(houseWork.icon),
                                const SizedBox(width: 8),
                                Text(houseWork.title),
                              ],
                            ),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedHouseWorkId = value;
                        _selectedHouseWork = houseWorks.firstWhere(
                          (hw) => hw.id == value,
                          orElse: () => houseWorks.first,
                        );
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '家事を選択してください';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 選択された家事の詳細表示
                  if (_selectedHouseWork != null) ...[
                    ListTile(
                      leading: Text(
                        _selectedHouseWork!.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(_selectedHouseWork!.title),
                      subtitle:
                          _selectedHouseWork!.description != null
                              ? Text(_selectedHouseWork!.description!)
                              : null,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // メモ入力欄
                  TextFormField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      labelText: 'メモ（任意）',
                      border: OutlineInputBorder(),
                      hintText: '実行時のメモを入力',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  // 家事ログの完了時刻入力欄
                  ListTile(
                    title: const Text('完了時刻'),
                    subtitle: Text(dateFormat.format(_completedAt)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _selectDateTime(context),
                  ),
                  const SizedBox(height: 16),

                  // 家事ログの実行したユーザー表示
                  ListTile(
                    title: const Text('実行したユーザー'),
                    subtitle: Text(currentUser?.displayName ?? 'ゲスト'),
                    leading: const Icon(Icons.person),
                  ),
                  const SizedBox(height: 24),

                  // 登録ボタン
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        '家事ログを登録する',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
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
    if (_formKey.currentState!.validate() && _selectedHouseWorkId != null) {
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
        houseWorkId: _selectedHouseWorkId!, // 選択された家事のID
        completedAt: _completedAt, // 完了時刻
        completedBy: currentUser.uid, // 実行ユーザー
        note:
            _noteController.text.isNotEmpty ? _noteController.text : null, // メモ
      );

      try {
        // 家事ログを保存
        workLogRepository.save(houseId, workLog);

        // 保存成功メッセージを表示
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('家事ログを登録しました')));

          // 一覧画面に戻る（更新フラグをtrueにして渡す）
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
