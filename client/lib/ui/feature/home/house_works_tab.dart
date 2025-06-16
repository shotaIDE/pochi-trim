import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pochi_trim/data/model/house_work.dart';
import 'package:pochi_trim/ui/feature/home/house_work_item.dart';
import 'package:pochi_trim/ui/feature/home/house_works_presenter.dart';
import 'package:skeletonizer/skeletonizer.dart';

class HouseWorksTab extends ConsumerStatefulWidget {
  const HouseWorksTab({
    super.key,
    required this.onCompleteButtonTap,
    required this.onLongPress,
  });

  final void Function(HouseWork) onCompleteButtonTap;
  final void Function(HouseWork) onLongPress;

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
              onDelete: widget.onLongPress,
            );
          },
          separatorBuilder: (_, _) => const _Divider(),
        );
      },
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1);
  }
}
