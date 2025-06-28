import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pochi_trim/data/model/house_work.dart';
import 'package:pochi_trim/ui/feature/home/add_house_work_screen.dart';
import 'package:pochi_trim/ui/feature/home/house_work_item.dart';
import 'package:pochi_trim/ui/feature/home/house_works_presenter.dart';
import 'package:skeletonizer/skeletonizer.dart';

class HouseWorksTab extends ConsumerStatefulWidget {
  const HouseWorksTab({
    super.key,
    required this.onCompleteButtonTap,
    required this.onLongPressHouseWork,
  });

  final void Function(HouseWork) onCompleteButtonTap;
  final void Function(HouseWork) onLongPressHouseWork;

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
            onLongPress: (_) {},
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
          return const _EmptyStateWidget();
        }

        return ListView.separated(
          itemCount: houseWorks.length,
          itemBuilder: (context, index) {
            final houseWork = houseWorks[index];

            return HouseWorkItem(
              houseWork: houseWork,
              onCompleteTap: widget.onCompleteButtonTap,
              onLongPress: widget.onLongPressHouseWork,
            );
          },
          separatorBuilder: (_, _) => const _Divider(),
        );
      },
    );
  }
}

class _EmptyStateWidget extends StatelessWidget {
  const _EmptyStateWidget();

  @override
  Widget build(BuildContext context) {
    final emptyIcon = Icon(
      Icons.egg,
      size: 64,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    final emptyText = Text(
      '家事が登録されていません',
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      textAlign: TextAlign.center,
    );
    final emptySubText = Text(
      '家事を登録し、ログを記録する準備をしましょう',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      textAlign: TextAlign.center,
    );
    final addButton = FilledButton.icon(
      onPressed: () {
        Navigator.of(context).push(AddHouseWorkScreen.route());
      },
      icon: const Icon(Icons.add),
      label: const Text('家事を登録する'),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        textStyle: Theme.of(context).textTheme.titleMedium,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 4,
        shadowColor: Theme.of(
          context,
        ).colorScheme.primary.withValues(alpha: 0.5),
      ),
    );

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            emptyIcon,
            const SizedBox(height: 24),
            emptyText,
            const SizedBox(height: 12),
            emptySubText,
            const SizedBox(height: 32),
            addButton,
          ],
        ),
      ),
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
