import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/models/work_log.dart';
import 'package:intl/intl.dart';

class WorkLogDetailScreen extends ConsumerWidget {
  const WorkLogDetailScreen({super.key, required this.workLog});
  final WorkLog workLog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 日付フォーマッター
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('家事ログ詳細')),
      body: SingleChildScrollView(
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
                      workLog.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (workLog.isRecurring)
                          const Chip(
                            label: Text('繰り返し'),
                            backgroundColor: Colors.blue,
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (workLog.description != null &&
                        workLog.description!.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '詳細:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            workLog.description!,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    const Divider(),
                    const SizedBox(height: 8),
                    _buildInfoRow('作成日時', dateFormat.format(workLog.createdAt)),
                    _buildInfoRow('作成者', workLog.createdBy),
                    _buildInfoRow(
                      '完了日時',
                      workLog.completedAt != null
                          ? dateFormat.format(workLog.completedAt!)
                          : '-',
                    ),
                    _buildInfoRow('実行者', workLog.completedBy ?? '-'),
                    if (workLog.isRecurring &&
                        workLog.recurringInterval != null)
                      _buildInfoRow(
                        '繰り返し間隔',
                        _formatDuration(workLog.recurringInterval!),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
