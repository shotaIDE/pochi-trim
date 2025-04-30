import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/models/house_work.dart';
import 'package:house_worker/models/work_log.dart';
import 'package:house_worker/repositories/house_work_repository.dart';
import 'package:intl/intl.dart';

class WorkLogDetailScreen extends ConsumerWidget {
  const WorkLogDetailScreen({super.key, required this.workLog});

  final WorkLog workLog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 日付フォーマッター
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');

    // 対応する家事情報を取得
    final houseWorkAsync = ref.watch(
      FutureProvider<HouseWork?>((ref) {
        final repository = ref.read(houseWorkRepositoryProvider);
        return repository.getByIdOnce(houseWorkId: workLog.houseWorkId);
      }),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('家事ログ詳細')),
      body: houseWorkAsync.when(
        data: (houseWork) => _buildContent(context, houseWork, dateFormat),
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, stack) => Center(child: Text('家事データの読み込みに失敗しました: $error')),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    HouseWork? houseWork,
    DateFormat dateFormat,
  ) {
    // 家事データが見つからない場合
    if (houseWork == null) {
      return const Center(child: Text('この家事ログに関連する家事データが見つかりませんでした'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    houseWork.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (houseWork.isRecurring)
                        const Chip(
                          label: Text('繰り返し'),
                          backgroundColor: Colors.blue,
                        ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  // WorkLogの情報を表示
                  _buildInfoRow('実行日時', dateFormat.format(workLog.completedAt)),
                  _buildInfoRow('実行者', workLog.completedBy),

                  if (houseWork.isRecurring &&
                      houseWork.recurringIntervalMs != null)
                    _buildInfoRow(
                      '繰り返し間隔',
                      _formatDuration(
                        Duration(milliseconds: houseWork.recurringIntervalMs!),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}日';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}時間';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}分';
    } else {
      return '${duration.inSeconds}秒';
    }
  }
}
