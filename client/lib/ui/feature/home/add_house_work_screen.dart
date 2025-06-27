import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pochi_trim/data/model/max_house_work_limit_exceeded_exception.dart';
import 'package:pochi_trim/data/repository/dao/add_house_work_args.dart';
import 'package:pochi_trim/data/service/auth_service.dart';
import 'package:pochi_trim/ui/feature/home/add_house_work_presenter.dart';
import 'package:pochi_trim/ui/feature/pro/upgrade_to_pro_screen.dart';

// カテゴリ別の絵文字リスト
class _EmojiCategory {
  const _EmojiCategory({
    required this.name,
    required this.emojis,
  });

  final String name;
  final List<String> emojis;
}

const _emojiCategories = <_EmojiCategory>[
  _EmojiCategory(
    name: '掃除',
    emojis: ['🧹', '🧽', '🧼', '🧺', '🧴', '🧯', '🪣', '🗑️'],
  ),
  _EmojiCategory(
    name: '水回り',
    emojis: ['🛁', '🚿', '🚽', '🪥', '🧻', '💧', '🌊', '🪠'],
  ),
  _EmojiCategory(
    name: 'キッチン',
    emojis: ['🍽️', '🍴', '🥄', '🍳', '🥘', '🍲', '🥣', '🧂'],
  ),
  _EmojiCategory(
    name: '洗濯',
    emojis: ['👕', '👖', '🧦', '🩲', '👗', '🧥', '🪣', '🧺'],
  ),
  _EmojiCategory(
    name: 'ペット',
    emojis: ['🐕', '🐈', '🐦', '🐠', '🐹', '🐰', '🦎', '🕊️'],
  ),
  _EmojiCategory(
    name: 'その他',
    emojis: ['🏠', '🛏️', '🪑', '🚪', '🪟', '💡', '🔧', '📱'],
  ),
];

// 全ての絵文字を一つのリストにまとめる
final List<String> _allEmojis = _emojiCategories
    .expand((category) => category.emojis)
    .toList();

// ランダムな絵文字を取得する関数
String getRandomEmoji() {
  final random = Random();
  return _allEmojis[random.nextInt(_allEmojis.length)];
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
      builder: (context) => _EmojiCategoryDialog(currentIcon: _icon),
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

class _EmojiCategoryDialog extends StatefulWidget {
  const _EmojiCategoryDialog({required this.currentIcon});

  final String currentIcon;

  @override
  State<_EmojiCategoryDialog> createState() => _EmojiCategoryDialogState();
}

class _EmojiCategoryDialogState extends State<_EmojiCategoryDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _emojiCategories.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('アイコンを選択'),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            // カテゴリタブ
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: _emojiCategories
                  .map((category) => Tab(text: category.name))
                  .toList(),
            ),
            const SizedBox(height: 16),
            // 各カテゴリの絵文字グリッド
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _emojiCategories.map((category) {
                  return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                        ),
                    itemCount: category.emojis.length,
                    itemBuilder: (context, index) {
                      final emoji = category.emojis[index];
                      return InkWell(
                        onTap: () => Navigator.of(context).pop(emoji),
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
                            border: widget.currentIcon == emoji
                                ? Border.all(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    width: 2,
                                  )
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 28),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
      ],
    );
  }
}
