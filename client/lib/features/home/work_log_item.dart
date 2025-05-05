import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/features/home/work_log_provider.dart';
import 'package:house_worker/models/house_work.dart';
import 'package:house_worker/models/work_log.dart';
import 'package:house_worker/repositories/house_work_repository.dart';
import 'package:house_worker/services/work_log_service.dart';
import 'package:intl/intl.dart';

// WorkLogに対応するHouseWorkを取得するプロバイダー
final FutureProviderFamily<HouseWork?, WorkLog> _houseWorkForLogProvider =
    FutureProvider.family<HouseWork?, WorkLog>((ref, workLog) {
      final houseWorkRepository = ref.watch(houseWorkRepositoryProvider);

      return houseWorkRepository.getByIdOnce(workLog.houseWorkId);
    });

class WorkLogItem extends ConsumerStatefulWidget {
  const WorkLogItem({
    super.key,
    required this.workLog,
    required this.onTap,
    this.onComplete,
  });

  final WorkLog workLog;
  final VoidCallback onTap;
  final VoidCallback? onComplete;

  @override
  ConsumerState<WorkLogItem> createState() => _WorkLogItemState();
}

class _WorkLogItemState extends ConsumerState<WorkLogItem> {
  @override
  Widget build(BuildContext context) {
    final houseWorkAsync = ref.watch(_houseWorkForLogProvider(widget.workLog));

    // TODO(ide): `Dismissible` を共通化
    return Dismissible(
      key: Key('workLog-${widget.workLog.id}'),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _onDelete(),
      child: ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainer,
        child: InkWell(
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: houseWorkAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('エラー: $err'),
              data: (houseWork) {
                // HouseWorkがnullの場合は代替表示
                final icon = houseWork?.icon ?? '📝';
                final title = houseWork?.title ?? '不明な家事';
                // WorkLogは常に完了しているので以下の条件分岐は不要
                // const isCompleted = true;

                const completedIcon = Icon(Icons.check_circle);
                final houseWorkIcon = Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.only(right: 12),
                  child: Text(icon, style: const TextStyle(fontSize: 24)),
                );
                final houseWorkTitleText = Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                );
                final completedDateTimeText = _CompletedDateText(
                  completedAt: widget.workLog.completedAt,
                );
                final completedContentPart = InkWell(
                  onTap: () {
                    // TODO(ide): 実装
                  },
                  child: Row(
                    children: [
                      completedIcon,
                      const SizedBox(width: 12),
                      houseWorkIcon,
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 4,
                          children: [houseWorkTitleText, completedDateTimeText],
                        ),
                      ),
                    ],
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
                  message: 'この家事を記録する',
                  child: InkWell(
                    onTap: () async {
                      await HapticFeedback.mediumImpact();

                      final workLogService = ref.read(workLogServiceProvider);

                      final isSucceeded = await workLogService.recordWorkLog(
                        houseWorkId: widget.workLog.houseWorkId,
                      );

                      if (!context.mounted) {
                        return;
                      }

                      // TODO(ide): 共通化できる
                      if (!isSucceeded) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('家事の記録に失敗しました。')),
                        );
                        return;
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('家事を記録しました')),
                      );
                    },
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
                );

                return IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(child: completedContentPart),
                      verticalDivider,
                      duplicatePart,
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onDelete() async {
    final workLogDeletion = ref.read(workLogDeletionProvider);

    await workLogDeletion.deleteWorkLog(widget.workLog);

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
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');
    return Text(
      '完了: ${dateFormat.format(completedAt ?? DateTime.now())}',
      style: const TextStyle(fontSize: 14, color: Colors.grey),
      overflow: TextOverflow.ellipsis,
    );
  }
}
