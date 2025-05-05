import 'package:flutter/material.dart';
import 'package:house_worker/models/house_work.dart';

class HouseWorkItem extends StatelessWidget {
  const HouseWorkItem({
    super.key,
    required this.houseWork,
    required this.onCompleteTap,
    required this.onMoveTap,
    required this.onDelete,
  });

  final HouseWork houseWork;
  final void Function(HouseWork) onCompleteTap;
  final void Function(HouseWork) onMoveTap;
  final void Function(HouseWork) onDelete;

  @override
  Widget build(BuildContext context) {
    final deleteIcon = Icon(
      Icons.delete,
      color: Theme.of(context).colorScheme.onSurface,
    );

    final doCompleteIcon = Icon(
      Icons.check_circle_outline,
      color: Theme.of(context).colorScheme.onSurface,
    );
    final houseWorkIcon = Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      width: 40,
      height: 40,
      child: Text(houseWork.icon, style: const TextStyle(fontSize: 24)),
    );
    final houseWorkTitleText = Text(
      houseWork.title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
    final completeButtonPart = InkWell(
      onTap: () => onCompleteTap(houseWork),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            doCompleteIcon,
            const SizedBox(width: 16),
            houseWorkIcon,
            const SizedBox(width: 12),
            Expanded(child: houseWorkTitleText),
          ],
        ),
      ),
    );

    final verticalDivider = Column(
      children: [
        Expanded(
          child: ColoredBox(
            color: Theme.of(context).dividerColor.withAlpha(100),
            child: const SizedBox(width: 1),
          ),
        ),
      ],
    );

    const dashboardIcon = Icon(Icons.chevron_right);
    final moveToDashboardPart = InkWell(
      onTap: () => onMoveTap(houseWork),
      child: const Column(
        children: [
          Expanded(
            child: Padding(padding: EdgeInsets.all(16), child: dashboardIcon),
          ),
        ],
      ),
    );

    // completeButtonPart の高さに他のウィジェットの高さを合わせるために IntrinsicHeight を使用
    final item = IntrinsicHeight(
      child: ColoredBox(
        color: Theme.of(context).colorScheme.surface,
        child: Row(
          children: [
            Expanded(child: completeButtonPart),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: verticalDivider,
            ),
            moveToDashboardPart,
          ],
        ),
      ),
    );

    return Dismissible(
      key: Key('houseWork-${houseWork.id}'),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: deleteIcon,
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        onDelete(houseWork);

        return false;
      },
      child: item,
    );
  }
}
