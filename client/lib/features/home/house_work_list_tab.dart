import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/features/home/house_work_item.dart';
import 'package:house_worker/features/home/house_work_list_presenter.dart';
import 'package:house_worker/features/home/work_log_dashboard_screen.dart';
import 'package:house_worker/models/house_work.dart';
import 'package:house_worker/models/work_log.dart';
import 'package:skeletonizer/skeletonizer.dart';

class HouseWorkListTab extends ConsumerStatefulWidget {
  const HouseWorkListTab({super.key});

  @override
  ConsumerState<HouseWorkListTab> createState() => _HouseWorkListTabState();
}

class _HouseWorkListTabState extends ConsumerState<HouseWorkListTab> {
  @override
  Widget build(BuildContext context) {
    final houseWorksFuture = ref.watch(houseWorksProvider.future);

    return FutureBuilder(
      future: houseWorksFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          final error = snapshot.error;

          const errorIcon = Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          );
          final errorText = Text(
            'エラーが発生しました: $error',
            style: const TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          );

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 16,
              children: [errorIcon, errorText],
            ),
          );
        }

        final houseWorks = snapshot.data;

        if (houseWorks == null) {
          return Skeletonizer(
            child: ListView.separated(
              itemCount: 10,
              itemBuilder: (context, index) => const _SkeletonHouseWorkItem(),
              separatorBuilder: (_, _) => const _Divider(),
            ),
          );
        }

        if (houseWorks.isEmpty) {
          const emptyIcon = Icon(Icons.home_work, size: 64, color: Colors.grey);
          const emptyText = Text(
            '登録されている家事はありません。\n家事を追加すると、ここに表示されます',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          );

          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 16,
              children: [emptyIcon, emptyText],
            ),
          );
        }

        return ListView.separated(
          itemCount: houseWorks.length,
          itemBuilder: (context, index) {
            final houseWork = houseWorks[index];

            return HouseWorkItem(
              houseWork: houseWork,
              onLeftTap: () => _onCompleteTapped(houseWork),
              onRightTap: () => _onWorkLogDashboardTapped(houseWork),
              onDelete: () => _onDeleteTapped(houseWork),
            );
          },
          separatorBuilder: (_, _) => const _Divider(),
        );
      },
    );
  }

  Future<void> _onCompleteTapped(HouseWork houseWork) async {
    final result = await ref.read(
      onCompleteHouseWorkTappedResultProvider(houseWork).future,
    );

    if (!mounted) {
      return;
    }

    if (!result) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('家事の記録に失敗しました。しばらくしてから再度お試しください')),
      );
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('家事を記録しました')));
  }

  Future<void> _onWorkLogDashboardTapped(HouseWork houseWork) async {
    if (!mounted) {
      return;
    }

    final workLog = WorkLog(
      id: '',
      houseWorkId: houseWork.id,
      completedAt: DateTime.now(),
      completedBy: '',
    );

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => WorkLogDashboardScreen(workLog: workLog),
      ),
    );
  }

  Future<void> _onDeleteTapped(HouseWork houseWork) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('家事の削除'),
            content: const Text('この家事を削除してもよろしいですか？'),
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

    final isSucceeded = await ref.read(
      deleteHouseWorkProvider(houseWork.id).future,
    );

    if (!mounted) {
      return;
    }

    if (!isSucceeded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('家事の削除に失敗しました。しばらくしてから再度お試しください')),
      );
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('家事を削除しました')));
  }
}

class _SkeletonHouseWorkItem extends StatelessWidget {
  const _SkeletonHouseWorkItem();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 12),
              child: const Text('🏠', style: TextStyle(fontSize: 24)),
            ),
            const Expanded(
              child: Text(
                'サンプル家事',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1);
  }
}
