import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/models/house_work.dart';
import 'package:house_worker/models/work_log.dart';
import 'package:house_worker/repositories/house_work_repository.dart';
import 'package:house_worker/repositories/work_log_repository.dart';
import 'package:house_worker/services/house_id_provider.dart';

// 家事ごとの頻度分析のためのデータクラス
class HouseWorkFrequency {
  HouseWorkFrequency({required this.houseWork, required this.count});
  final HouseWork houseWork;
  final int count;
}

// 曜日ごとの頻度分析のためのデータクラス
class WeekdayFrequency {
  WeekdayFrequency({required this.weekday, required this.count});
  final String weekday;
  final int count;
}

// 家事ログの取得と分析のためのプロバイダー
final workLogsForAnalysisProvider = FutureProvider<List<WorkLog>>((ref) {
  final workLogRepository = ref.watch(workLogRepositoryProvider);
  final houseId = ref.watch(currentHouseIdProvider);
  return workLogRepository.getAll(houseId);
});

// 各家事の実行頻度を取得するプロバイダー
final houseWorkFrequencyProvider = FutureProvider<List<HouseWorkFrequency>>((
  ref,
) async {
  // 家事ログのデータを待機
  final workLogs = await ref.watch(workLogsForAnalysisProvider.future);
  final houseWorkRepository = ref.watch(houseWorkRepositoryProvider);
  final houseId = ref.watch(currentHouseIdProvider);

  // 家事IDごとにグループ化して頻度をカウント
  final frequencyMap = <String, int>{};
  for (final workLog in workLogs) {
    frequencyMap[workLog.houseWorkId] =
        (frequencyMap[workLog.houseWorkId] ?? 0) + 1;
  }

  // HouseWorkFrequencyのリストを作成
  final result = <HouseWorkFrequency>[];
  for (final entry in frequencyMap.entries) {
    final houseWork = await houseWorkRepository.getByIdOnce(
      houseId: houseId,
      houseWorkId: entry.key,
    );

    if (houseWork != null) {
      result.add(HouseWorkFrequency(houseWork: houseWork, count: entry.value));
    }
  }

  // 頻度の高い順にソート
  result.sort((a, b) => b.count.compareTo(a.count));

  return result;
});

// 曜日ごとの家事実行頻度を取得するプロバイダー
final weekdayFrequencyProvider = FutureProvider<List<WeekdayFrequency>>((
  ref,
) async {
  // 家事ログのデータを待機
  final workLogs = await ref.watch(workLogsForAnalysisProvider.future);

  // 曜日名の配列（インデックスは0が日曜日）
  final weekdayNames = ['日曜日', '月曜日', '火曜日', '水曜日', '木曜日', '金曜日', '土曜日'];

  // 曜日ごとにグループ化して頻度をカウント
  final frequencyMap = <int, int>{};
  for (final workLog in workLogs) {
    final weekday = workLog.completedAt.weekday % 7; // 0-6の値（0が日曜日）
    frequencyMap[weekday] = (frequencyMap[weekday] ?? 0) + 1;
  }

  // 日曜日から土曜日の順に並べたWeekdayFrequencyのリストを作成
  final result = <WeekdayFrequency>[];
  for (var i = 0; i < 7; i++) {
    result.add(
      WeekdayFrequency(weekday: weekdayNames[i], count: frequencyMap[i] ?? 0),
    );
  }

  return result;
});

/// 分析画面
///
/// 家事の実行頻度や曜日ごとの頻度分析を表示する
class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  /// 分析方式
  /// 0: 家事の頻度分析
  /// 1: 曜日ごとの頻度分析
  var _analysisMode = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('分析'),
        // ホーム画面への動線
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Column(
        children: [
          // 分析方式の切り替えUI
          _buildAnalysisModeSwitcher(),

          // 分析結果表示
          Expanded(
            child:
                _analysisMode == 0
                    ? _buildFrequencyAnalysis()
                    : _buildWeekdayAnalysis(),
          ),
        ],
      ),
    );
  }

  /// 分析方式の切り替えUIを構築
  Widget _buildAnalysisModeSwitcher() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SegmentedButton<int>(
        segments: const [
          ButtonSegment<int>(value: 0, label: Text('家事の頻度分析')),
          ButtonSegment<int>(value: 1, label: Text('曜日ごとの頻度分析')),
        ],
        selected: {_analysisMode},
        onSelectionChanged: (Set<int> newSelection) {
          setState(() {
            _analysisMode = newSelection.first;
          });
        },
      ),
    );
  }

  /// 家事の頻度分析を表示するウィジェットを構築
  Widget _buildFrequencyAnalysis() {
    return Consumer(
      builder: (context, ref, child) {
        final frequencyDataAsync = ref.watch(houseWorkFrequencyProvider);

        return frequencyDataAsync.when(
          data: (frequencyData) {
            if (frequencyData.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.data_usage, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      '家事ログがありません',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '家事を完了すると、ここに分析結果が表示されます',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '家事の実行頻度（回数が多い順）',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: frequencyData.length,
                        itemBuilder: (context, index) {
                          final item = frequencyData[index];
                          return ListTile(
                            leading: Text(
                              item.houseWork.icon,
                              style: const TextStyle(fontSize: 24),
                            ),
                            title: Text(item.houseWork.title),
                            trailing: Text(
                              '${item.count}回',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error:
              (error, stackTrace) => Center(
                child: Text('エラーが発生しました: $error', textAlign: TextAlign.center),
              ),
        );
      },
    );
  }

  /// 曜日ごとの頻度分析を表示するウィジェットを構築
  Widget _buildWeekdayAnalysis() {
    return Consumer(
      builder: (context, ref, child) {
        final weekdayDataAsync = ref.watch(weekdayFrequencyProvider);

        return weekdayDataAsync.when(
          data: (weekdayData) {
            if (weekdayData.every((data) => data.count == 0)) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      '家事ログがありません',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '家事を完了すると、ここに分析結果が表示されます',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            // 最大値を取得（グラフの描画に使用）
            final maxCount = weekdayData
                .map((e) => e.count)
                .reduce((a, b) => a > b ? a : b);

            return Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '曜日ごとの家事実行頻度',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: weekdayData.length,
                        itemBuilder: (context, index) {
                          final item = weekdayData[index];
                          // 最大値に対する割合に基づいてバーの長さを決定
                          final ratio =
                              maxCount > 0
                                  ? item.count / maxCount.toDouble()
                                  : 0;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.weekday),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(
                                      flex: (ratio * 100).toInt(),
                                      child: Container(
                                        height: 24,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                    if (ratio < 1)
                                      Expanded(
                                        flex: 100 - (ratio * 100).toInt(),
                                        child: Container(),
                                      ),
                                    const SizedBox(width: 8),
                                    Text('${item.count}回'),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error:
              (error, stackTrace) => Center(
                child: Text('エラーが発生しました: $error', textAlign: TextAlign.center),
              ),
        );
      },
    );
  }
}
