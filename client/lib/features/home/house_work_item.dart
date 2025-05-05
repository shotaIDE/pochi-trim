import 'package:flutter/material.dart';
import 'package:house_worker/models/house_work.dart';

class HouseWorkItem extends StatelessWidget {
  const HouseWorkItem({
    super.key,
    required this.houseWork,
    required this.onLeftTap,
    required this.onRightTap,
    required this.onDelete,
  });

  final HouseWork houseWork;
  final void Function(HouseWork) onLeftTap;
  final void Function(HouseWork) onRightTap;
  final void Function(HouseWork) onDelete;

  @override
  Widget build(BuildContext context) {
    final deleteIcon = Icon(
      Icons.delete,
      color: Theme.of(context).colorScheme.onSurface,
    );

    // TODO(ide): 共通化できそう
    final houseWorkIcon = Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      width: 40,
      height: 40,
      margin: const EdgeInsets.only(right: 12),
      child: Text(houseWork.icon, style: const TextStyle(fontSize: 24)),
    );
    final houseWorkTitleText = Text(
      houseWork.title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
    final completeButtonPart = InkWell(
      onTap: () => onLeftTap(houseWork),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [houseWorkIcon, Expanded(child: houseWorkTitleText)],
        ),
      ),
    );

    const dashboardIcon = Icon(Icons.chevron_right);
    final moveToDashboardPart = InkWell(
      onTap: () => onRightTap(houseWork),
      child: dashboardIcon,
    );

    final item = Row(
      children: [Expanded(child: completeButtonPart), moveToDashboardPart],
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
