import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/features/analysis/analysis_period.dart';
import 'package:house_worker/features/analysis/analysis_presenter.dart';
import 'package:house_worker/models/house_work.dart';
import 'package:house_worker/models/work_log.dart';
import 'package:house_worker/repositories/house_work_repository.dart';
import 'package:house_worker/repositories/work_log_repository.dart';
import 'package:intl/intl.dart';

// 家事ごとの頻度分析のためのデータクラス
class HouseWorkFrequency {
  HouseWorkFrequency({
    required this.houseWork,
    required this.count,
    // TODO(ide): デフォルト引数を廃止する
    this.color = Colors.grey,
  });

  final HouseWork houseWork;
  final int count;
  final Color color;
}

// 時間帯別の家事実行頻度のためのデータクラス
class TimeSlotFrequency {
  TimeSlotFrequency({
    required this.timeSlot,
    required this.houseWorkFrequencies,
    required this.totalCount,
  });
  final String timeSlot; // 時間帯の表示名（例：「0-3時」）
  final List<HouseWorkFrequency> houseWorkFrequencies; // その時間帯での家事ごとの実行回数
  final int totalCount; // その時間帯の合計実行回数

  // fl_chartのBarChartRodData作成用のヘルパーメソッド
  BarChartRodData toBarChartRodData({
    required double width,
    required double x,
    required List<Color> colors,
  }) {
    // 家事の実行回数ごとにRodStackItemを作成
    final rodStackItems = <BarChartRodStackItem>[];

    double fromY = 0;
    for (var i = 0; i < houseWorkFrequencies.length; i++) {
      final item = houseWorkFrequencies[i];
      final toY = fromY + item.count;

      rodStackItems.add(
        BarChartRodStackItem(fromY, toY, colors[i % colors.length]),
      );

      fromY = toY;
    }

    return BarChartRodData(
      toY: totalCount.toDouble(),
      width: width,
      color: Colors.transparent,
      rodStackItems: rodStackItems,
      borderRadius: BorderRadius.zero,
    );
  }
}

// 家事ログの取得と分析のためのプロバイダー
final workLogsForAnalysisProvider = FutureProvider<List<WorkLog>>((ref) {
  final workLogRepository = ref.watch(workLogRepositoryProvider);

  return workLogRepository.getAllOnce();
});

// 各家事の実行頻度を取得するプロバイダー
final houseWorkFrequencyProvider = FutureProvider<List<HouseWorkFrequency>>((
  ref,
) async {
  // 家事ログのデータを待機
  final workLogs = await ref.watch(workLogsForAnalysisProvider.future);
  final houseWorkRepository = ref.watch(houseWorkRepositoryProvider);

  // 家事IDごとにグループ化して頻度をカウント
  final frequencyMap = <String, int>{};
  for (final workLog in workLogs) {
    frequencyMap[workLog.houseWorkId] =
        (frequencyMap[workLog.houseWorkId] ?? 0) + 1;
  }

  // HouseWorkFrequencyのリストを作成
  final result = <HouseWorkFrequency>[];
  for (final entry in frequencyMap.entries) {
    final houseWork = await houseWorkRepository.getByIdOnce(entry.key);

    if (houseWork != null) {
      result.add(HouseWorkFrequency(houseWork: houseWork, count: entry.value));
    }
  }

  // 頻度の高い順にソート
  result.sort((a, b) => b.count.compareTo(a.count));

  return result;
});

// 各家事の実行頻度を取得するプロバイダー（期間フィルタリング付き）
final filteredHouseWorkFrequencyProvider =
    FutureProvider<List<HouseWorkFrequency>>((ref) async {
      // フィルタリングされた家事ログのデータを待機
      final workLogs = await ref.watch(workLogsFilteredByPeriodProvider.future);
      final houseWorkRepository = ref.watch(houseWorkRepositoryProvider);

      // 家事IDごとにグループ化して頻度をカウント
      final frequencyMap = <String, int>{};
      for (final workLog in workLogs) {
        frequencyMap[workLog.houseWorkId] =
            (frequencyMap[workLog.houseWorkId] ?? 0) + 1;
      }

      // HouseWorkFrequencyのリストを作成
      final result = <HouseWorkFrequency>[];
      for (final entry in frequencyMap.entries) {
        final houseWork = await houseWorkRepository.getByIdOnce(entry.key);

        if (houseWork != null) {
          result.add(
            HouseWorkFrequency(houseWork: houseWork, count: entry.value),
          );
        }
      }

      // 頻度の高い順にソート
      result.sort((a, b) => b.count.compareTo(a.count));

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

  /// 分析期間
  /// 0: 今日
  /// 1: 今週
  /// 2: 今月
  var _analysisPeriodLegacy = 1; // デフォルトは「今週」

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
          Padding(
            padding: const EdgeInsets.all(16),
            child: _AnalysisPeriodSwitcher(
              onPeriodChangedLegacy: (period) {
                setState(() {
                  _analysisPeriodLegacy = period;
                });
              },
            ),
          ),

          // 分析方式の切り替えUI
          _buildAnalysisModeSwitcher(),

          // 分析結果表示
          Expanded(
            child: () {
              switch (_analysisMode) {
                case 0:
                  return _buildFrequencyAnalysis();
                case 1:
                  return const _WeekdayAnalysisPanel();
                case 2:
                  return _TimeSlotAnalysisPanel(
                    analysisPeriod: _analysisPeriodLegacy,
                  );
                default:
                  return _buildFrequencyAnalysis();
              }
            }(),
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
          ButtonSegment<int>(value: 1, label: Text('曜日による分析')),
          ButtonSegment<int>(value: 2, label: Text('時間帯による分析')),
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
        // 選択された期間に基づいてフィルタリングされたデータを取得
        final frequencyDataAsync = ref.watch(
          filteredHouseWorkFrequencyProvider,
        );

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

            // 期間に応じたタイトルのテキストを作成
            final periodText = _getPeriodTextLegacy(
              analysisPeriod: _analysisPeriodLegacy,
            );

            return Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$periodTextの家事実行頻度（回数が多い順）',
                      style: const TextStyle(
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
}

class _AnalysisPeriodSwitcher extends ConsumerWidget {
  const _AnalysisPeriodSwitcher({required this.onPeriodChangedLegacy});

  final void Function(int period) onPeriodChangedLegacy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysisPeriod = ref.watch(currentAnalysisPeriodProvider);

    final dropdownButton = DropdownButton<int>(
      value: _getPeriodValue(analysisPeriod),
      items: const [
        DropdownMenuItem(value: 0, child: Text('今日')),
        DropdownMenuItem(value: 1, child: Text('今週')),
        DropdownMenuItem(value: 2, child: Text('今月')),
      ],
      onChanged: (value) {
        if (value == null) {
          return;
        }

        final period = _getPeriod(value);
        ref.read(currentAnalysisPeriodProvider.notifier).setPeriod(period);
      },
    );

    final dateTimeFormat = DateFormat('yyyy/MM/dd');
    final periodText = Text(
      '${dateTimeFormat.format(analysisPeriod.from)}'
      '- ${dateTimeFormat.format(analysisPeriod.to)}',
    );

    return Row(
      spacing: 8,
      children: [
        const Text('分析期間: ', style: TextStyle(fontWeight: FontWeight.bold)),
        dropdownButton,
        periodText,
      ],
    );
  }

  int _getPeriodValue(AnalysisPeriod analysisPeriod) {
    switch (analysisPeriod) {
      case AnalysisPeriodToday _:
        return 0;
      case AnalysisPeriodCurrentWeek _:
        return 1;
      case AnalysisPeriodCurrentMonth _:
        return 2;
    }
  }

  AnalysisPeriod _getPeriod(int value) {
    final current = DateTime.now();

    switch (value) {
      case 0:
        return AnalysisPeriodTodayGenerator.fromCurrentDate(current);
      case 1:
        return AnalysisPeriodCurrentWeekGenerator.fromCurrentDate(current);
      case 2:
        return AnalysisPeriodCurrentMonthGenerator.fromCurrentDate(current);
      default:
        throw ArgumentError('Invalid value: $value');
    }
  }
}

class _WeekdayAnalysisPanel extends ConsumerWidget {
  const _WeekdayAnalysisPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 選択された期間に基づいてフィルタリングされたデータを取得
    final statisticsFuture = ref.watch(weekdayStatisticsDisplayProvider.future);

    return FutureBuilder(
      future: statisticsFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              'エラーが発生しました。画面を再読み込みしてください。',
              textAlign: TextAlign.center,
            ),
          );
        }

        final statistics = snapshot.data;
        if (statistics == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final weekdayFrequencies = statistics.weekdayFrequencies;

        if (weekdayFrequencies.every((data) => data.totalCount == 0)) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  '家事ログがありません',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                const _WeekdayAnalysisPanelTitle(),
                const SizedBox(height: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16, right: 16),
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                            ),
                          ),
                          rightTitles: const AxisTitles(),
                          topTitles: const AxisTitles(),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                if (value < 0 ||
                                    value >= weekdayFrequencies.length) {
                                  return const Text('');
                                }
                                return Text(
                                  weekdayFrequencies[value.toInt()]
                                      .weekday
                                      .displayName,
                                );
                              },
                            ),
                          ),
                        ),
                        gridData: const FlGridData(
                          horizontalInterval: 4,
                          drawVerticalLine: false,
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border(
                            left: BorderSide(
                              color: Theme.of(context).dividerColor,
                            ),
                            bottom: BorderSide(
                              color: Theme.of(context).dividerColor,
                            ),
                          ),
                        ),
                        barGroups:
                            weekdayFrequencies.asMap().entries.map((entry) {
                              final index = entry.key;
                              final data = entry.value;

                              // 家事ごとの色を一貫させるために、houseWorkIdに基づいて色を割り当てる
                              final rodStackItems = <BarChartRodStackItem>[];
                              double fromY = 0;

                              // 表示されている家事だけを処理
                              for (final freq in data.houseWorkFrequencies) {
                                final toY = fromY + freq.count;

                                rodStackItems.add(
                                  BarChartRodStackItem(fromY, toY, freq.color),
                                );

                                fromY = toY;
                              }

                              return BarChartGroupData(
                                x: index,
                                barRods: [
                                  BarChartRodData(
                                    toY: data.totalCount.toDouble(),
                                    width: 20,
                                    color: Colors.transparent,
                                    rodStackItems: rodStackItems,
                                    borderRadius: BorderRadius.zero,
                                  ),
                                ],
                              );
                            }).toList(),
                        rotationQuarterTurns: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // 凡例の表示（タップ可能）
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(26), // 0.1 * 255 = 約26
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '凡例: (タップで表示/非表示を切り替え)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        children:
                            statistics.houseWorkLegends.map((houseWorkLegend) {
                              return InkWell(
                                onTap: () {
                                  ref
                                      .read(
                                        houseWorkVisibilitiesProvider.notifier,
                                      )
                                      .toggle(
                                        houseWorkId:
                                            houseWorkLegend.houseWork.id,
                                      );
                                },
                                child: Opacity(
                                  opacity:
                                      houseWorkLegend.isVisible ? 1.0 : 0.3,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 16,
                                          height: 16,
                                          color: houseWorkLegend.color,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          houseWorkLegend.houseWork.title,
                                          style: TextStyle(
                                            fontSize: 12,
                                            decoration:
                                                houseWorkLegend.isVisible
                                                    ? null
                                                    : TextDecoration
                                                        .lineThrough,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TimeSlotAnalysisPanel extends ConsumerWidget {
  const _TimeSlotAnalysisPanel({required this.analysisPeriod});

  final int analysisPeriod;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 選択された期間に基づいてフィルタリングされたデータを取得
    final timeSlotDataAsync = ref.watch(filteredTimeSlotFrequencyProvider);

    return timeSlotDataAsync.when(
      data: (timeSlotData) {
        if (timeSlotData.every((data) => data.totalCount == 0)) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.access_time, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  '家事ログがありません',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

        // 期間に応じたタイトルのテキストを作成
        final periodText = _getPeriodTextLegacy(analysisPeriod: analysisPeriod);

        // 家事ごとの積み上げ棒グラフのための色リスト
        final colors = [
          Colors.blue,
          Colors.green,
          Colors.orange,
          Colors.purple,
          Colors.teal,
          Colors.pink,
          Colors.amber,
          Colors.indigo,
        ];

        // 凡例データの収集
        final allHouseWorks = <HouseWork>{};
        final houseWorkColorMap = <String, Color>{};

        // すべての家事を収集し、それぞれに色を割り当てる
        for (final slot in timeSlotData) {
          for (var i = 0; i < slot.houseWorkFrequencies.length; i++) {
            final houseWork = slot.houseWorkFrequencies[i].houseWork;
            allHouseWorks.add(houseWork);
            if (!houseWorkColorMap.containsKey(houseWork.id)) {
              houseWorkColorMap[houseWork.id] =
                  colors[houseWorkColorMap.length % colors.length];
            }
          }
        }

        // 家事を集約してリスト化（凡例用）
        final legendItems = allHouseWorks.toList();

        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$periodTextの時間帯ごとの家事実行頻度',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16, right: 16),
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: timeSlotData
                            .map((e) => e.totalCount.toDouble())
                            .reduce((a, b) => a > b ? a : b),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                            ),
                          ),
                          rightTitles: const AxisTitles(),
                          topTitles: const AxisTitles(),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                if (value < 0 || value >= timeSlotData.length) {
                                  return const Text('');
                                }
                                return Text(
                                  timeSlotData[value.toInt()].timeSlot,
                                );
                              },
                            ),
                          ),
                        ),
                        gridData: const FlGridData(
                          horizontalInterval: 4,
                          drawVerticalLine: false,
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border(
                            left: BorderSide(
                              color: Theme.of(context).dividerColor,
                            ),
                            bottom: BorderSide(
                              color: Theme.of(context).dividerColor,
                            ),
                          ),
                        ),
                        barGroups:
                            timeSlotData.asMap().entries.map((entry) {
                              final index = entry.key;
                              final data = entry.value;

                              return BarChartGroupData(
                                x: index,
                                barRods: [
                                  data.toBarChartRodData(
                                    width: 20,
                                    x: index.toDouble(),
                                    colors: colors,
                                  ),
                                ],
                              );
                            }).toList(),
                        rotationQuarterTurns: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // 凡例の表示
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(26), // 0.1 * 255 = 約26
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '凡例:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children:
                            legendItems.map((houseWork) {
                              final color =
                                  houseWorkColorMap[houseWork.id] ?? colors[0];
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    color: color,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    houseWork.title,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              );
                            }).toList(),
                      ),
                    ],
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
  }
}

class _WeekdayAnalysisPanelTitle extends ConsumerWidget {
  const _WeekdayAnalysisPanelTitle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysisPeriod = ref.watch(currentAnalysisPeriodProvider);

    final periodText = _getPeriodText(analysisPeriod: analysisPeriod);

    return Text(
      '$periodTextの曜日ごとの家事実行頻度',
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }
}

String _getPeriodText({required AnalysisPeriod analysisPeriod}) {
  switch (analysisPeriod) {
    case AnalysisPeriodToday _:
      return '今日';
    case AnalysisPeriodCurrentWeek _:
      return '今週';
    case AnalysisPeriodCurrentMonth _:
      return '今月';
  }
}

String _getPeriodTextLegacy({required int analysisPeriod}) {
  switch (analysisPeriod) {
    case 0:
      return '今日';
    case 1:
      return '今週';
    case 2:
      return '今月';
    default:
      return '';
  }
}
