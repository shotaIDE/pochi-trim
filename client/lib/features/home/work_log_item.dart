import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/features/home/work_log_included_house_work.dart';
import 'package:house_worker/features/home/work_log_provider.dart';
import 'package:house_worker/services/work_log_service.dart';
import 'package:intl/intl.dart';

class WorkLogItem extends ConsumerStatefulWidget {
  const WorkLogItem({
    super.key,
    required this.workLogIncludedHouseWork,
    required this.onTap,
    this.onComplete,
  });

  final WorkLogIncludedHouseWork workLogIncludedHouseWork;
  final VoidCallback onTap;
  final VoidCallback? onComplete;

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
      child: Text(houseWork.icon, style: const TextStyle(fontSize: 24)),
    );
    final houseWorkTitleText = Text(
      houseWork.title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
    final completedDateTimeText = _CompletedDateText(
      completedAt: widget.workLogIncludedHouseWork.completedAt,
    );
    final completedContentPart = GestureDetector(
      onLongPress: () {
        // TODO(ide): 実装
      },
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            completedDateTimeText,
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

    final duplicateIcon = Icon(
      Icons.copy,
      color: Theme.of(context).colorScheme.onSurface,
    );
    final duplicatePart = Tooltip(
      message: 'この家事を再度記録する',
      child: InkWell(
        onTap: () async {
          await HapticFeedback.mediumImpact();

          final workLogService = ref.read(workLogServiceProvider);

          final isSucceeded = await workLogService.recordWorkLog(
            houseWorkId: widget.workLogIncludedHouseWork.id,
          );

          if (!context.mounted) {
            return;
          }

          // TODO(ide): 共通化できる
          if (!isSucceeded) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('家事の記録に失敗しました。')));
            return;
          }

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('家事を記録しました')));
        },
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
      child: Row(
        children: [
          Expanded(child: completedContentPart),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: verticalDivider,
          ),
          duplicatePart,
        ],
      ),
    );

    // TODO(ide): `Dismissible` を共通化
    return Dismissible(
      key: Key('workLog-${widget.workLogIncludedHouseWork.id}'),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _onDelete(),
      child: body,
    );
  }

  Future<void> _onDelete() async {
    final workLogDeletion = ref.read(workLogDeletionProvider);

    await workLogDeletion.deleteWorkLog(
      widget.workLogIncludedHouseWork.toWorkLog(),
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.delete, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text('家事ログを削除しました')),
          ],
        ),
        action: SnackBarAction(
          label: '元に戻す',
          onPressed: () async {
            final workLogDeletion = ref.read(workLogDeletionProvider);
            await workLogDeletion.undoDelete();
          },
        ),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _CompletedDateText extends StatelessWidget {
  const _CompletedDateText({required this.completedAt});

  final DateTime? completedAt;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd');
    final timeFormat = DateFormat('HH:mm');

    return Column(
      children: [
        Text(
          dateFormat.format(completedAt ?? DateTime.now()),
          style: const TextStyle(fontSize: 14, color: Colors.grey),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          timeFormat.format(completedAt ?? DateTime.now()),
          style: const TextStyle(fontSize: 14, color: Colors.grey),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
