import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/models/house_work.dart';
import 'package:house_worker/repositories/house_work_repository.dart';
import 'package:house_worker/services/auth_service.dart';
import 'package:house_worker/services/house_id_provider.dart'; // 共通のプロバイダーをインポート

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

class HouseWorkAddScreen extends ConsumerStatefulWidget {
  const HouseWorkAddScreen({super.key, this.existingHouseWork});

  // 既存の家事から新しい家事を作成するためのファクトリコンストラクタ
  factory HouseWorkAddScreen.fromExistingHouseWork(HouseWork houseWork) {
    return HouseWorkAddScreen(existingHouseWork: houseWork);
  }
  final HouseWork? existingHouseWork;

  @override
  ConsumerState<HouseWorkAddScreen> createState() => _HouseWorkAddScreenState();
}

class _HouseWorkAddScreenState extends ConsumerState<HouseWorkAddScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;

  var _icon = '🏠';
  var _isRecurring = false;
  int? _recurringIntervalMs;

  @override
  void initState() {
    super.initState();
    // 既存の家事がある場合は、そのデータを初期値として設定
    if (widget.existingHouseWork != null) {
      final hw = widget.existingHouseWork!;
      _titleController = TextEditingController(text: hw.title);
      _icon = hw.icon;
      _isRecurring = hw.isRecurring;
      _recurringIntervalMs = hw.recurringIntervalMs;
    } else {
      _titleController = TextEditingController();
      _icon = getRandomEmoji(); // デフォルトでランダムな絵文字を設定
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingHouseWork != null ? '家事を編集' : '家事追加'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // アイコン選択
              Row(
                children: [
                  GestureDetector(
                    onTap: _selectEmoji,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color:
                            Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          _icon,
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: '家事名',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '家事名を入力してください';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 繰り返し設定
              SwitchListTile(
                title: const Text('定期的な家事'),
                subtitle: const Text('定期的に行う家事の場合はONにしてください'),
                value: _isRecurring,
                onChanged: (value) {
                  setState(() {
                    _isRecurring = value;
                  });
                },
              ),

              // 繰り返し設定が有効な場合に間隔を選択できるようにする
              if (_isRecurring) ...[
                const SizedBox(height: 8),
                ListTile(
                  title: const Text('繰り返し間隔'),
                  subtitle: Text(_getRecurringIntervalText()),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: _selectRecurringInterval,
                ),
              ],

              const SizedBox(height: 24),

              // 登録ボタン
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    widget.existingHouseWork != null ? '家事を更新する' : '家事を登録する',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectEmoji() async {
    // 簡易的な絵文字選択ダイアログを表示
    final selectedEmoji = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('アイコンを選択'),
            content: SizedBox(
              width: double.maxFinite,
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: _emojiList.length,
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () => Navigator.of(context).pop(_emojiList[index]),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color:
                            Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          _emojiList[index],
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
    );

    if (selectedEmoji != null) {
      setState(() {
        _icon = selectedEmoji;
      });
    }
  }

  String _getRecurringIntervalText() {
    if (_recurringIntervalMs == null) {
      return '設定なし';
    }

    // ミリ秒を適切な単位に変換
    final days = _recurringIntervalMs! ~/ (1000 * 60 * 60 * 24);
    if (days > 0) {
      return '$days日ごと';
    }

    final hours = _recurringIntervalMs! ~/ (1000 * 60 * 60);
    if (hours > 0) {
      return '$hours時間ごと';
    }

    final minutes = _recurringIntervalMs! ~/ (1000 * 60);
    return '$minutes分ごと';
  }

  Future<void> _selectRecurringInterval() async {
    // 簡易的な期間選択ダイアログを表示
    final intervals = [
      {'label': '毎日', 'value': 1000 * 60 * 60 * 24},
      {'label': '2日ごと', 'value': 1000 * 60 * 60 * 24 * 2},
      {'label': '3日ごと', 'value': 1000 * 60 * 60 * 24 * 3},
      {'label': '1週間ごと', 'value': 1000 * 60 * 60 * 24 * 7},
      {'label': '2週間ごと', 'value': 1000 * 60 * 60 * 24 * 14},
      {'label': '1ヶ月ごと', 'value': 1000 * 60 * 60 * 24 * 30},
    ];

    final selectedInterval = await showDialog<int>(
      context: context,
      builder:
          (context) => SimpleDialog(
            title: const Text('繰り返し間隔'),
            children:
                intervals
                    .map(
                      (interval) => SimpleDialogOption(
                        onPressed:
                            () => Navigator.of(
                              context,
                            ).pop(interval['value']! as int),
                        child: Text(interval['label']! as String),
                      ),
                    )
                    .toList(),
          ),
    );

    if (selectedInterval != null) {
      setState(() {
        _recurringIntervalMs = selectedInterval;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final houseWorkRepository = ref.read(houseWorkRepositoryProvider);
      final currentUser = ref.read(authServiceProvider).currentUser;
      final houseId = ref.read(currentHouseIdProvider);

      if (currentUser == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('ユーザー情報が取得できませんでした')));
        return;
      }

      // 新しい家事を作成
      final houseWork = HouseWork(
        id: widget.existingHouseWork?.id ?? '', // 編集時は既存のID、新規作成時は空文字列
        title: _titleController.text,
        icon: _icon,
        createdAt: widget.existingHouseWork?.createdAt ?? DateTime.now(),
        createdBy: widget.existingHouseWork?.createdBy ?? currentUser.uid,
        isRecurring: _isRecurring,
        recurringIntervalMs: _isRecurring ? _recurringIntervalMs : null,
      );

      try {
        // 家事を保存
        houseWorkRepository.save(houseId, houseWork);

        // 保存成功メッセージを表示
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.existingHouseWork != null ? '家事を更新しました' : '家事を登録しました',
              ),
            ),
          );

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
