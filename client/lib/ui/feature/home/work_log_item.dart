import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pochi_trim/ui/feature/home/work_log_included_house_work.dart';

class WorkLogItem extends ConsumerStatefulWidget {
  const WorkLogItem({
    super.key,
    required this.workLogIncludedHouseWork,
    required this.onDuplicate,
    required this.onDelete,
    this.onLongPress,
  });

  final WorkLogIncludedHouseWork workLogIncludedHouseWork;
  final void Function(WorkLogIncludedHouseWork) onDuplicate;
  final void Function(WorkLogIncludedHouseWork) onDelete;
  final void Function(WorkLogIncludedHouseWork)? onLongPress;

  @override
  ConsumerState<WorkLogItem> createState() => _WorkLogItemState();
}

class _WorkLogItemState extends ConsumerState<WorkLogItem> {
  @override
  Widget build(BuildContext context) {
    final houseWork = widget.workLogIncludedHouseWork.houseWork;

    final houseWorkIcon = Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      width: 40,
      height: 40,
      child: Text(
        houseWork.icon,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    );
    final houseWorkTitleText = Text(
      houseWork.title,
      style: Theme.of(context).textTheme.titleMedium,
    );
    final completedDateTimeText = _CompletedDateText(
      completedAt: widget.workLogIncludedHouseWork.completedAt,
    );
    final completedContentPart = Row(
      children: [
        completedDateTimeText,
        const SizedBox(width: 16),
        houseWorkIcon,
        const SizedBox(width: 12),
        Expanded(child: houseWorkTitleText),
      ],
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

    final duplicateIcon = Icon(
      Icons.copy,
      color: Theme.of(context).colorScheme.onSurface,
    );
    final duplicatePart = Tooltip(
      message: 'この家事を再度記録する',
      child: InkWell(
        onTap: () => widget.onDuplicate(widget.workLogIncludedHouseWork),
        child: ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainer,
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: duplicateIcon,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final body = IntrinsicHeight(
      // 以下の理由で `GestureDetector` ではなく `InkWell` を使用している
      // - ロングタップが検知された時に Haptic フィードバックが発生するため、UXが良い
      // - 反応精度が高い
      child: InkWell(
        onLongPress: widget.onLongPress != null
            ? () => widget.onLongPress!(widget.workLogIncludedHouseWork)
            : null,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: completedContentPart,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: verticalDivider,
            ),
            duplicatePart,
          ],
        ),
      ),
    );

    return Dismissible(
      key: Key('workLog-${widget.workLogIncludedHouseWork.id}'),
      background: Container(
        color: Theme.of(context).colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete, color: Theme.of(context).colorScheme.onError),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => widget.onDelete(widget.workLogIncludedHouseWork),
      child: body,
    );
  }
}

class _CompletedDateText extends StatelessWidget {
  const _CompletedDateText({required this.completedAt});

  final DateTime completedAt;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd');
    final timeFormat = DateFormat('HH:mm');
    final color = Theme.of(context).colorScheme.onSurface.withAlpha(100);

    return Column(
      children: [
        Text(
          dateFormat.format(completedAt),
          style: Theme.of(
            context,
          ).textTheme.labelMedium!.copyWith(color: color),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          timeFormat.format(completedAt),
          style: Theme.of(
            context,
          ).textTheme.labelMedium!.copyWith(color: color),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
