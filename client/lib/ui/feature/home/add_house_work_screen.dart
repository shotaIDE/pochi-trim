import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pochi_trim/data/model/max_house_work_limit_exceeded_exception.dart';
import 'package:pochi_trim/data/repository/dao/add_house_work_args.dart';
import 'package:pochi_trim/data/service/auth_service.dart';
import 'package:pochi_trim/ui/feature/home/add_house_work_presenter.dart';
import 'package:pochi_trim/ui/feature/pro/upgrade_to_pro_screen.dart';

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

class AddHouseWorkScreen extends ConsumerStatefulWidget {
  const AddHouseWorkScreen({super.key});

  static const name = 'AddHouseWorkScreen';

  static MaterialPageRoute<AddHouseWorkScreen> route() =>
      MaterialPageRoute<AddHouseWorkScreen>(
        builder: (_) => const AddHouseWorkScreen(),
        settings: const RouteSettings(name: name),
        fullscreenDialog: true,
      );

  @override
  ConsumerState<AddHouseWorkScreen> createState() => _AddHouseWorkScreenState();
}

class _AddHouseWorkScreenState extends ConsumerState<AddHouseWorkScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;

  var _icon = '🏠';

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController();
    _icon = getRandomEmoji();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('家事追加')),
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
                        color: Theme.of(
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

              const SizedBox(height: 24),

              // 登録ボタン
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('家事を登録する', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectEmoji() async {
    final selectedEmoji = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('アイコンを選択'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: _emojiList.length,
            itemBuilder: (context, index) {
              return InkWell(
                onTap: () => Navigator.of(context).pop(_emojiList[index]),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: _icon == _emojiList[index]
                        ? Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          )
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      _emojiList[index],
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );

    if (selectedEmoji != null) {
      setState(() {
        _icon = selectedEmoji;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final userProfile = await ref.read(currentUserProfileProvider.future);

    if (!mounted) {
      return;
    }

    if (userProfile == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ユーザー情報が取得できませんでした')));
      return;
    }

    final args = AddHouseWorkArgs(
      title: _titleController.text,
      icon: _icon,
      createdAt: DateTime.now(),
      createdBy: userProfile.id,
    );

    try {
      await ref.read(saveHouseWorkResultProvider(args).future);
    } on MaxHouseWorkLimitExceededException {
      if (!mounted) {
        return;
      }

      await _showProUpgradeDialog(
        'フリー版では最大10件までの家事しか登録できません。Pro版にアップグレードすると、無制限に家事を登録できます。',
      );
      return;
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('家事を登録しました')));

    Navigator.of(context).pop();
  }

  Future<void> _showProUpgradeDialog(String message) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('制限に達しました'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(UpgradeToProScreen.route());
            },
            child: const Text('Pro版にアップグレード'),
          ),
        ],
      ),
    );
  }
}
