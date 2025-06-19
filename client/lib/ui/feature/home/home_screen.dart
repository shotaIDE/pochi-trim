import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pochi_trim/data/model/delete_house_work_exception.dart';
import 'package:pochi_trim/data/model/delete_work_log_exception.dart';
import 'package:pochi_trim/data/model/house_work.dart';
import 'package:pochi_trim/data/service/system_service.dart';
import 'package:pochi_trim/data/service/work_log_service.dart';
import 'package:pochi_trim/ui/feature/analysis/analysis_screen.dart';
import 'package:pochi_trim/ui/feature/home/add_house_work_screen.dart';
import 'package:pochi_trim/ui/feature/home/home_presenter.dart';
import 'package:pochi_trim/ui/feature/home/house_works_tab.dart';
import 'package:pochi_trim/ui/feature/home/work_log_included_house_work.dart';
import 'package:pochi_trim/ui/feature/home/work_logs_tab.dart';
import 'package:pochi_trim/ui/feature/settings/settings_screen.dart';
import 'package:skeletonizer/skeletonizer.dart';

enum _HouseWorkAction { delete }

// 選択されたタブを管理するプロバイダー
final selectedTabProvider = StateProvider<int>((ref) => 0);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  static const name = 'HomeScreen';

  static MaterialPageRoute<HomeScreen> route() => MaterialPageRoute<HomeScreen>(
    builder: (_) => const HomeScreen(),
    settings: const RouteSettings(name: name),
  );

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  var _isLogTabHighlighted = false;

  @override
  Widget build(BuildContext context) {
    final selectedTab = ref.watch(selectedTabProvider);
    final isDeletingHouseWork = ref.watch(isHouseWorkDeletingProvider);

    const titleText = Text('記録');

    final analysisButton = IconButton(
      onPressed: () {
        Navigator.of(context).push(AnalysisScreen.route());
      },
      tooltip: '分析を表示する',
      icon: const Icon(Icons.analytics),
    );
    final settingsButton = IconButton(
      onPressed: () {
        Navigator.of(context).push(SettingsScreen.route());
      },
      tooltip: '設定を表示する',
      icon: const Icon(Icons.settings),
    );

    const homeWorksTabItem = Tooltip(
      message: '登録されている家事を表示する',
      child: Tab(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 8,
          children: [Icon(Icons.list_alt), Text('家事')],
        ),
      ),
    );
    final workLogsTabItem = Tooltip(
      message: '完了した家事ログを表示する',
      child: AnimatedContainer(
        // TODO(ide): 文字サイズが変わった時にも固定サイズで問題ないか？
        padding: const EdgeInsets.symmetric(vertical: 12),
        duration: const Duration(milliseconds: 250),
        color: _isLogTabHighlighted
            ? Theme.of(context).highlightColor
            : Colors.transparent,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 8,
          children: [Icon(Icons.check_circle), Text('ログ')],
        ),
      ),
    );
    final tabBar = TabBar(
      onTap: (index) {
        ref.read(selectedTabProvider.notifier).state = index;
      },
      tabs: [homeWorksTabItem, workLogsTabItem],
    );

    final addHouseWorkButton = FloatingActionButton(
      tooltip: '家事を追加する',
      onPressed: () {
        Navigator.of(context).push(AddHouseWorkScreen.route());
      },
      child: const Icon(Icons.add),
    );

    return DefaultTabController(
      length: 2,
      initialIndex: selectedTab,
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              title: titleText,
              actions: [analysisButton, settingsButton],
              bottom: tabBar,
            ),
            body: TabBarView(
              children: [
                HouseWorksTab(
                  onCompleteButtonTap: _onCompleteHouseWorkButtonTap,
                  onLongPressHouseWork: _onLongPressHouseWork,
                ),
                WorkLogsTab(onDuplicateButtonTap: _onDuplicateWorkLogButtonTap),
              ],
            ),
            floatingActionButton: addHouseWorkButton,
            bottomNavigationBar: _QuickRegisterBottomBar(
              onTap: _onQuickRegisterButtonPressed,
            ),
          ),
          if (isDeletingHouseWork)
            ColoredBox(
              color: Theme.of(context).colorScheme.scrim.withAlpha(128),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 16,
                  children: [
                    const CircularProgressIndicator(),
                    Text(
                      '家事を削除しています...',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        // TODO(ide): テーマの色を利用したい
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _onCompleteHouseWorkButtonTap(HouseWork houseWork) async {
    final workLogId = await ref.read(
      onCompleteHouseWorkButtonTappedResultProvider(houseWork).future,
    );

    if (!mounted) {
      return;
    }

    if (workLogId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('家事ログの記録に失敗しました。しばらくしてから再度お試しください')),
      );
      return;
    }

    _highlightWorkLogsTabItem();

    _showWorkLogRegisteredSnackBar(workLogId);
  }

  Future<void> _onDuplicateWorkLogButtonTap(
    WorkLogIncludedHouseWork workLogIncludedHouseWork,
  ) async {
    final workLogId = await ref.read(
      onDuplicateWorkLogButtonTappedResultProvider(
        workLogIncludedHouseWork,
      ).future,
    );

    if (!mounted) {
      return;
    }

    // TODO(ide): 共通化できる
    if (workLogId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('家事ログの記録に失敗しました。しばらくしてから再度お試しください')),
      );
      return;
    }

    _showWorkLogRegisteredSnackBar(workLogId);
  }

  Future<void> _onQuickRegisterButtonPressed(HouseWork houseWork) async {
    final workLogService = ref.read(workLogServiceProvider);
    final systemService = ref.read(systemServiceProvider);

    final workLogId = await workLogService.recordWorkLog(
      houseWorkId: houseWork.id,
      onRequestAccepted: systemService.doHapticFeedbackActionReceived,
    );

    if (!mounted) {
      return;
    }

    // TODO(ide): 共通化
    if (workLogId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('家事ログの記録に失敗しました。しばらくしてから再度お試しください')),
      );
      return;
    }

    final selectedTab = ref.read(selectedTabProvider);
    if (selectedTab == 0) {
      // 家事タブが選択されている場合は、ログタブの方に家事の登録が完了したことを通知する
      _highlightWorkLogsTabItem();
    }

    _showWorkLogRegisteredSnackBar(workLogId);
  }

  Future<void> _onLongPressHouseWork(HouseWork houseWork) async {
    // TODO(ide): Haptic Feedbackが欲しい
    final action = await showModalBottomSheet<_HouseWorkAction>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('削除する'),
                onTap: () => Navigator.of(context).pop(_HouseWorkAction.delete),
              ),
            ],
          ),
        );
      },
      clipBehavior: Clip.antiAlias,
    );

    if (action != _HouseWorkAction.delete) {
      return;
    }

    if (!mounted) {
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('家事の削除'),
        content: const Text(
          'この家事を削除してもよろしいですか？\n'
          '\n'
          '※この操作は取り消すことができません。\n'
          '※登録した家事ログも見れなくなります。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      await ref
          .read(isHouseWorkDeletingProvider.notifier)
          .deleteHouseWork(houseWork);
    } on DeleteHouseWorkException {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('家事の削除に失敗しました。しばらくしてから再度お試しください')),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('家事を削除しました')));
  }

  void _highlightWorkLogsTabItem() {
    setState(() {
      _isLogTabHighlighted = true;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isLogTabHighlighted = false;
        });
      }
    });
  }

  void _showWorkLogRegisteredSnackBar(String workLogId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('家事ログを記録しました'),
        action: SnackBarAction(
          label: '取り消す',
          onPressed: () => _undoWorkLog(workLogId),
        ),
      ),
    );
  }

  Future<void> _undoWorkLog(String workLogId) async {
    try {
      await ref.read(undoWorkLogProvider(workLogId).future);
    } on DeleteWorkLogException {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('家事ログの取り消しに失敗しました')));
      }
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('家事ログの記録を取り消しました')));
  }
}

class _QuickRegisterBottomBar extends ConsumerWidget {
  const _QuickRegisterBottomBar({required this.onTap});

  final void Function(HouseWork) onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final houseWorksFuture = ref.watch(
      houseWorksSortedByMostFrequentlyUsedProvider.future,
    );

    return Container(
      constraints: const BoxConstraints(maxHeight: 130),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(77), // 0.3 * 255 = 約77
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: FutureBuilder<List<HouseWork>>(
          future: houseWorksFuture,
          builder: (context, snapshot) {
            return Skeletonizer(
              enabled: snapshot.data == null,
              child: _buildContent(snapshot),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(AsyncSnapshot<List<HouseWork>> snapshot) {
    if (snapshot.hasError) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'クイック登録の取得に失敗しました。アプリを再起動し、再度お試しください。',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final recentHouseWorks = snapshot.data;

    if (recentHouseWorks == null) {
      return ListView(
        scrollDirection: Axis.horizontal,
        children: List.filled(4, const _FakeQuickRegisterButton()),
      );
    }

    final items = recentHouseWorks.map((houseWork) {
      return _QuickRegisterButton(houseWork: houseWork, onTap: onTap);
    }).toList();

    return ListView(scrollDirection: Axis.horizontal, children: items);
  }
}

class _QuickRegisterButton extends ConsumerWidget {
  const _QuickRegisterButton({required this.houseWork, required this.onTap});

  final HouseWork houseWork;
  final void Function(HouseWork) onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: 100,
      child: InkWell(
        onTap: () => onTap(houseWork),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 4,
            children: [
              Container(
                alignment: Alignment.center,
                // TODO(ide): 共通化できる
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                width: 32,
                height: 32,
                child: Text(
                  houseWork.icon,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              Text(
                houseWork.title,
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FakeQuickRegisterButton extends StatelessWidget {
  const _FakeQuickRegisterButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            Container(
              alignment: Alignment.center,
              width: 32,
              height: 32,
              child: const Text('🙇🏻‍♂️', style: TextStyle(fontSize: 24)),
            ),
            const Text(
              'Fake house work',
              style: TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
