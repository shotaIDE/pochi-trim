import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/data/model/house_work.dart';
import 'package:house_worker/ui/feature/home/house_work_item.dart';
import 'package:house_worker/ui/feature/home/house_works_presenter.dart';
import 'package:skeletonizer/skeletonizer.dart';

class HouseWorksTab extends ConsumerStatefulWidget {
  const HouseWorksTab({super.key, required this.onCompleteButtonTap});

  final void Function(HouseWork) onCompleteButtonTap;

  @override
  ConsumerState<HouseWorksTab> createState() => _HouseWorksTabState();
}

class _HouseWorksTabState extends ConsumerState<HouseWorksTab> {
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
          final dummyHouseWorkItem = HouseWorkItem(
            houseWork: HouseWork(
              id: 'dummyId',
              title: 'Dummy House Work',
              icon: '🏠',
              createdAt: DateTime.now(),
              createdBy: 'DummyUser',
            ),
            onCompleteTap: (_) {},
            onDelete: (_) {},
          );

          return Skeletonizer(
            child: ListView.separated(
              itemCount: 10,
              itemBuilder: (context, index) => dummyHouseWorkItem,
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
              onCompleteTap: widget.onCompleteButtonTap,
              onDelete: _onDeleteTapped,
            );
          },
          separatorBuilder: (_, _) => const _Divider(),
        );
      },
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

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1);
  }
}
