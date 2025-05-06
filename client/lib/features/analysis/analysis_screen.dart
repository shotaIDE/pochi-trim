import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/features/analysis/analysis_period.dart';
import 'package:house_worker/features/analysis/analysis_presenter.dart';
import 'package:house_worker/features/analysis/statistics.dart';
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
                  return const _TimeSlotAnalysisPanel();
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
        DropdownMenuItem(value: 1, child: Text('昨日')),
        DropdownMenuItem(value: 2, child: Text('今週')),
        DropdownMenuItem(value: 3, child: Text('今月')),
        DropdownMenuItem(value: 4, child: Text('過去1週間')),
        DropdownMenuItem(value: 5, child: Text('過去2週間')),
        DropdownMenuItem(value: 6, child: Text('過去1ヶ月')),
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
      case AnalysisPeriodYesterday _:
        return 1;
      case AnalysisPeriodCurrentWeek _:
        return 2;
      case AnalysisPeriodCurrentMonth _:
        return 3;
      case AnalysisPeriodPastWeek _:
        return 4;
      case AnalysisPeriodPastTwoWeeks _:
        return 5;
      case AnalysisPeriodPastMonth _:
        return 6;
    }
  }

  AnalysisPeriod _getPeriod(int value) {
    final current = DateTime.now();

    switch (value) {
      case 0:
        return AnalysisPeriodTodayGenerator.fromCurrentDate(current);
      case 1:
        return AnalysisPeriodYesterdayGenerator.fromCurrentDate(current);
      case 2:
        return AnalysisPeriodCurrentWeekGenerator.fromCurrentDate(current);
      case 3:
        return AnalysisPeriodCurrentMonthGenerator.fromCurrentDate(current);
      case 4:
        return AnalysisPeriodPastWeekGenerator.fromCurrentDate(current);
      case 5:
        return AnalysisPeriodPastTwoWeeksGenerator.fromCurrentDate(current);
      case 6:
        return AnalysisPeriodPastMonthGenerator.fromCurrentDate(current);
      default:
        throw ArgumentError('Invalid value: $value');
    }
  }
}

class _WeekdayAnalysisPanel extends ConsumerWidget {
  const _WeekdayAnalysisPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

        final barChart = BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 30),
              ),
              rightTitles: const AxisTitles(),
              topTitles: const AxisTitles(),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value < 0 || value >= weekdayFrequencies.length) {
                      return const Text('');
                    }
                    return Text(
                      weekdayFrequencies[value.toInt()].weekday.displayName,
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
                left: BorderSide(color: Theme.of(context).dividerColor),
                bottom: BorderSide(color: Theme.of(context).dividerColor),
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
        );

        return SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 16 + MediaQuery.of(context).viewPadding.left,
            top: 16,
            right: 16 + MediaQuery.of(context).viewPadding.right,
            bottom: 16 + MediaQuery.of(context).viewPadding.bottom,
          ),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 16,
                children: [
                  const _WeekdayAnalysisPanelTitle(),
                  Padding(
                    padding: const EdgeInsets.only(top: 16, right: 16),
                    child: SizedBox(
                      // TODO(ide): 固定サイズじゃなくしたい
                      height: 360,
                      child: barChart,
                    ),
                  ),
                  _Legends(
                    legends: statistics.houseWorkLegends,
                    onTap: (houseWorkId) {
                      ref
                          .read(houseWorkVisibilitiesProvider.notifier)
                          .toggle(houseWorkId: houseWorkId);
                    },
                    onLongPress: (houseWorkId) {
                      ref
                          .read(houseWorkVisibilitiesProvider.notifier)
                          .showOnlyOne(houseWorkId: houseWorkId);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TimeSlotAnalysisPanel extends ConsumerWidget {
  const _TimeSlotAnalysisPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statisticsFuture = ref.watch(
      currentTimeSlotStatisticsProvider.future,
    );

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

        final timeSlotFrequencies = statistics.timeSlotFrequencies;

        if (timeSlotFrequencies.every((data) => data.totalCount == 0)) {
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

        final barChart = BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: timeSlotFrequencies
                .map((e) => e.totalCount.toDouble())
                .reduce((a, b) => a > b ? a : b),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 30),
              ),
              rightTitles: const AxisTitles(),
              topTitles: const AxisTitles(),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value < 0 || value >= timeSlotFrequencies.length) {
                      return const Text('');
                    }
                    return Text(timeSlotFrequencies[value.toInt()].timeSlot);
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
                left: BorderSide(color: Theme.of(context).dividerColor),
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            barGroups:
                timeSlotFrequencies.asMap().entries.map((entry) {
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
        );

        return SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 16 + MediaQuery.of(context).viewPadding.left,
            top: 16,
            right: 16 + MediaQuery.of(context).viewPadding.right,
            bottom: 16 + MediaQuery.of(context).viewPadding.bottom,
          ),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 16,
                children: [
                  const _TimeSlotAnalysisPanelTitle(),
                  Padding(
                    padding: const EdgeInsets.only(top: 16, right: 16),
                    child: SizedBox(
                      // TODO(ide): 固定サイズじゃなくしたい
                      height: 500,
                      child: barChart,
                    ),
                  ),
                  _Legends(
                    legends: statistics.houseWorkLegends,
                    onTap: (houseWorkId) {
                      ref
                          .read(houseWorkVisibilitiesProvider.notifier)
                          .toggle(houseWorkId: houseWorkId);
                    },
                    onLongPress: (houseWorkId) {
                      ref
                          .read(houseWorkVisibilitiesProvider.notifier)
                          .showOnlyOne(houseWorkId: houseWorkId);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
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

class _TimeSlotAnalysisPanelTitle extends ConsumerWidget {
  const _TimeSlotAnalysisPanelTitle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysisPeriod = ref.watch(currentAnalysisPeriodProvider);

    final periodText = _getPeriodText(analysisPeriod: analysisPeriod);

    return Text(
      '$periodTextの時間帯ごとの家事実行頻度',
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }
}

String _getPeriodText({required AnalysisPeriod analysisPeriod}) {
  switch (analysisPeriod) {
    case AnalysisPeriodToday _:
      return '今日';
    case AnalysisPeriodYesterday _:
      return '昨日';
    case AnalysisPeriodCurrentWeek _:
      return '今週';
    case AnalysisPeriodCurrentMonth _:
      return '今月';
    case AnalysisPeriodPastWeek _:
      return '過去1週間';
    case AnalysisPeriodPastTwoWeeks _:
      return '過去2週間';
    case AnalysisPeriodPastMonth _:
      return '過去1ヶ月';
  }
}

class _Legends extends StatelessWidget {
  const _Legends({
    required this.legends,
    required this.onTap,
    required this.onLongPress,
  });

  final List<HouseWorkLegends> legends;
  final void Function(String houseWorkId) onTap;
  final void Function(String houseWorkId) onLongPress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(26), // 0.1 * 255 = 約26
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '凡例: (タップで表示/非表示を切り替え、ロングタップでその項目のみ表示)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            children:
                legends.map((legend) {
                  return InkWell(
                    onTap: () => onTap(legend.houseWork.id),
                    onLongPress: () => onLongPress(legend.houseWork.id),
                    child: Opacity(
                      opacity: legend.isVisible ? 1.0 : 0.3,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              color: legend.color,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              legend.houseWork.title,
                              style: TextStyle(
                                fontSize: 12,
                                decoration:
                                    legend.isVisible
                                        ? null
                                        : TextDecoration.lineThrough,
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
    );
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
