import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/features/analysis/day_of_the_week_frequency.dart';
import 'package:house_worker/models/house_work.dart';
import 'package:house_worker/models/work_log.dart';
import 'package:house_worker/repositories/house_work_repository.dart';
import 'package:house_worker/repositories/work_log_repository.dart';
import 'package:house_worker/services/house_id_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// 家事ごとの頻度分析のためのデータクラス
class HouseWorkFrequency {
  HouseWorkFrequency({required this.houseWork, required this.count});
  final HouseWork houseWork;
  final int count;
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
@riverpod
Future<List<DayOfTheWeekFrequency>> dayOfTheWeekFrequencies(Ref ref) async {
  // 家事ログのデータを待機
  final workLogs = await ref.watch(workLogsForAnalysisProvider.future);
  final houseWorkRepository = ref.watch(houseWorkRepositoryProvider);
  final houseId = ref.watch(currentHouseIdProvider);

  // 曜日名の配列（インデックスは0が日曜日）
  final weekdayNames = ['日曜日', '月曜日', '火曜日', '水曜日', '木曜日', '金曜日', '土曜日'];

  // 曜日ごと、家事IDごとにグループ化して頻度をカウント
  final weekdayMap = <int, Map<String, int>>{};
  // 各曜日の初期化
  for (var i = 0; i < 7; i++) {
    weekdayMap[i] = <String, int>{};
  }

  // 家事ログを曜日と家事IDでグループ化
  for (final workLog in workLogs) {
    final weekday = workLog.completedAt.weekday % 7; // 0-6の値（0が日曜日）
    final houseWorkId = workLog.houseWorkId;

    weekdayMap[weekday]![houseWorkId] =
        (weekdayMap[weekday]![houseWorkId] ?? 0) + 1;
  }

  // WeekdayFrequencyのリストを作成
  final result = <DayOfTheWeekFrequency>[];
  for (var i = 0; i < 7; i++) {
    final houseWorkFrequencies = <HouseWorkFrequency>[];
    var totalCount = 0;

    // 各家事IDごとの頻度を取得
    for (final entry in weekdayMap[i]!.entries) {
      final houseWork = await houseWorkRepository.getByIdOnce(
        houseId: houseId,
        houseWorkId: entry.key,
      );

      if (houseWork != null) {
        houseWorkFrequencies.add(
          HouseWorkFrequency(houseWork: houseWork, count: entry.value),
        );
        totalCount += entry.value;
      }
    }

    // 頻度の高い順にソート
    houseWorkFrequencies.sort((a, b) => b.count.compareTo(a.count));

    result.add(
      DayOfTheWeekFrequency(
        weekday: weekdayNames[i],
        houseWorkFrequencies: houseWorkFrequencies,
        totalCount: totalCount,
      ),
    );
  }

  return result;
}

// 期間で絞り込まれた家事ログの取得と分析のためのプロバイダー
final FutureProviderFamily<List<WorkLog>, int> filteredWorkLogsProvider =
    FutureProvider.family<List<WorkLog>, int>((ref, period) async {
      final workLogRepository = ref.watch(workLogRepositoryProvider);
      final houseId = ref.watch(currentHouseIdProvider);
      final allWorkLogs = await workLogRepository.getAll(houseId);

      // 現在時刻を取得
      final now = DateTime.now();

      // 期間によるフィルタリング
      switch (period) {
        case 0: // 今日
          final startOfDay = DateTime(now.year, now.month, now.day);
          final endOfDay = startOfDay
              .add(const Duration(days: 1))
              .subtract(const Duration(microseconds: 1));
          return allWorkLogs
              .where(
                (log) =>
                    log.completedAt.isAfter(startOfDay) &&
                    log.completedAt.isBefore(endOfDay),
              )
              .toList();

        case 1: // 今週
          // 週の開始は月曜日、終了は日曜日とする
          final currentWeekday = now.weekday;
          final startOfWeek = DateTime(
            now.year,
            now.month,
            now.day,
          ).subtract(Duration(days: currentWeekday - 1));
          final endOfWeek = startOfWeek
              .add(const Duration(days: 7))
              .subtract(const Duration(microseconds: 1));
          return allWorkLogs
              .where(
                (log) =>
                    log.completedAt.isAfter(startOfWeek) &&
                    log.completedAt.isBefore(endOfWeek),
              )
              .toList();

        case 2: // 今月
          final startOfMonth = DateTime(now.year, now.month);
          final endOfMonth =
              (now.month < 12)
                  ? DateTime(now.year, now.month + 1)
                  : DateTime(now.year + 1);
          final lastDayOfMonth = endOfMonth.subtract(
            const Duration(microseconds: 1),
          );
          return allWorkLogs
              .where(
                (log) =>
                    log.completedAt.isAfter(startOfMonth) &&
                    log.completedAt.isBefore(lastDayOfMonth),
              )
              .toList();

        default:
          return allWorkLogs;
      }
    });

// 各家事の実行頻度を取得するプロバイダー（期間フィルタリング付き）
final FutureProviderFamily<List<HouseWorkFrequency>, int>
filteredHouseWorkFrequencyProvider =
    FutureProvider.family<List<HouseWorkFrequency>, int>((ref, period) async {
      // フィルタリングされた家事ログのデータを待機
      final workLogs = await ref.watch(filteredWorkLogsProvider(period).future);
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
          result.add(
            HouseWorkFrequency(houseWork: houseWork, count: entry.value),
          );
        }
      }

      // 頻度の高い順にソート
      result.sort((a, b) => b.count.compareTo(a.count));

      return result;
    });

// 曜日ごとの家事実行頻度を取得するプロバイダー（期間フィルタリング付き）
final FutureProviderFamily<List<DayOfTheWeekFrequency>, int>
filteredWeekdayFrequencyProvider =
    FutureProvider.family<List<DayOfTheWeekFrequency>, int>((
      ref,
      period,
    ) async {
      // フィルタリングされた家事ログのデータを待機
      final workLogs = await ref.watch(filteredWorkLogsProvider(period).future);
      final houseWorkRepository = ref.watch(houseWorkRepositoryProvider);
      final houseId = ref.watch(currentHouseIdProvider);

      // 曜日名の配列（インデックスは0が日曜日）
      final weekdayNames = ['日曜日', '月曜日', '火曜日', '水曜日', '木曜日', '金曜日', '土曜日'];

      // 曜日ごと、家事IDごとにグループ化して頻度をカウント
      final weekdayMap = <int, Map<String, int>>{};
      // 各曜日の初期化
      for (var i = 0; i < 7; i++) {
        weekdayMap[i] = <String, int>{};
      }

      // 家事ログを曜日と家事IDでグループ化
      for (final workLog in workLogs) {
        final weekday = workLog.completedAt.weekday % 7; // 0-6の値（0が日曜日）
        final houseWorkId = workLog.houseWorkId;

        weekdayMap[weekday]![houseWorkId] =
            (weekdayMap[weekday]![houseWorkId] ?? 0) + 1;
      }

      // WeekdayFrequencyのリストを作成
      final result = <DayOfTheWeekFrequency>[];
      for (var i = 0; i < 7; i++) {
        final houseWorkFrequencies = <HouseWorkFrequency>[];
        var totalCount = 0;

        // 各家事IDごとの頻度を取得
        for (final entry in weekdayMap[i]!.entries) {
          final houseWork = await houseWorkRepository.getByIdOnce(
            houseId: houseId,
            houseWorkId: entry.key,
          );

          if (houseWork != null) {
            houseWorkFrequencies.add(
              HouseWorkFrequency(houseWork: houseWork, count: entry.value),
            );
            totalCount += entry.value;
          }
        }

        // 頻度の高い順にソート
        houseWorkFrequencies.sort((a, b) => b.count.compareTo(a.count));

        result.add(
          DayOfTheWeekFrequency(
            weekday: weekdayNames[i],
            houseWorkFrequencies: houseWorkFrequencies,
            totalCount: totalCount,
          ),
        );
      }

      return result;
    });

// 時間帯ごとの家事実行頻度を取得するプロバイダー（期間フィルタリング付き）
final FutureProviderFamily<List<TimeSlotFrequency>, int>
filteredTimeSlotFrequencyProvider =
    FutureProvider.family<List<TimeSlotFrequency>, int>((ref, period) async {
      // フィルタリングされた家事ログのデータを待機
      final workLogs = await ref.watch(filteredWorkLogsProvider(period).future);
      final houseWorkRepository = ref.watch(houseWorkRepositoryProvider);
      final houseId = ref.watch(currentHouseIdProvider);

      // 時間帯の定義（3時間ごと）
      final timeSlots = [
        '0-3時',
        '3-6時',
        '6-9時',
        '9-12時',
        '12-15時',
        '15-18時',
        '18-21時',
        '21-24時',
      ];

      // 時間帯ごと、家事IDごとにグループ化して頻度をカウント
      final timeSlotMap = <int, Map<String, int>>{};
      // 各時間帯の初期化
      for (var i = 0; i < 8; i++) {
        timeSlotMap[i] = <String, int>{};
      }

      // 家事ログを時間帯と家事IDでグループ化
      for (final workLog in workLogs) {
        final hour = workLog.completedAt.hour;
        final timeSlotIndex = hour ~/ 3; // 0-7のインデックス（3時間ごとの区分）
        final houseWorkId = workLog.houseWorkId;

        timeSlotMap[timeSlotIndex]![houseWorkId] =
            (timeSlotMap[timeSlotIndex]![houseWorkId] ?? 0) + 1;
      }

      // TimeSlotFrequencyのリストを作成
      final result = <TimeSlotFrequency>[];
      for (var i = 0; i < 8; i++) {
        final houseWorkFrequencies = <HouseWorkFrequency>[];
        var totalCount = 0;

        // 各家事IDごとの頻度を取得
        for (final entry in timeSlotMap[i]!.entries) {
          final houseWork = await houseWorkRepository.getByIdOnce(
            houseId: houseId,
            houseWorkId: entry.key,
          );

          if (houseWork != null) {
            houseWorkFrequencies.add(
              HouseWorkFrequency(houseWork: houseWork, count: entry.value),
            );
            totalCount += entry.value;
          }
        }

        // 頻度の高い順にソート
        houseWorkFrequencies.sort((a, b) => b.count.compareTo(a.count));

        result.add(
          TimeSlotFrequency(
            timeSlot: timeSlots[i],
            houseWorkFrequencies: houseWorkFrequencies,
            totalCount: totalCount,
          ),
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

  /// 分析期間
  /// 0: 今日
  /// 1: 今週
  /// 2: 今月
  var _analysisPeriod = 1; // デフォルトは「今週」

  // 分析期間の選択肢
  final _periodItems = [
    const DropdownMenuItem<int>(value: 0, child: Text('今日')),
    const DropdownMenuItem<int>(value: 1, child: Text('今週')),
    const DropdownMenuItem<int>(value: 2, child: Text('今月')),
  ];

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
          // 分析期間の切り替えUI
          _buildAnalysisPeriodSwitcher(),

          // 分析方式の切り替えUI
          _buildAnalysisModeSwitcher(),

          // 分析結果表示
          Expanded(
            child: () {
              switch (_analysisMode) {
                case 0:
                  return _buildFrequencyAnalysis();
                case 1:
                  return _WeekdayAnalysisPanel(analysisPeriod: _analysisPeriod);
                case 2:
                  return _TimeSlotAnalysisPanel(
                    analysisPeriod: _analysisPeriod,
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

  /// 分析期間の切り替えUIを構築
  Widget _buildAnalysisPeriodSwitcher() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Text('分析期間: ', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          DropdownButton<int>(
            value: _analysisPeriod,
            items: _periodItems,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _analysisPeriod = value;
                });
              }
            },
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
          filteredHouseWorkFrequencyProvider(_analysisPeriod),
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
            final periodText = _getPeriodText(analysisPeriod: _analysisPeriod);

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

class _WeekdayAnalysisPanel extends ConsumerWidget {
  const _WeekdayAnalysisPanel({required this.analysisPeriod});

  final int analysisPeriod;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 選択された期間に基づいてフィルタリングされたデータを取得
    final weekdayDataAsync = ref.watch(
      filteredWeekdayFrequencyProvider(analysisPeriod),
    );

    return weekdayDataAsync.when(
      data: (weekdayData) {
        if (weekdayData.every((data) => data.totalCount == 0)) {
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

        // 期間に応じたタイトルのテキストを作成
        final periodText = _getPeriodText(analysisPeriod: analysisPeriod);

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
        for (final day in weekdayData) {
          for (var i = 0; i < day.houseWorkFrequencies.length; i++) {
            final houseWork = day.houseWorkFrequencies[i].houseWork;
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
                  '$periodTextの曜日ごとの家事実行頻度',
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
                        maxY: weekdayData
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
                                if (value < 0 || value >= weekdayData.length) {
                                  return const Text('');
                                }
                                return Text(weekdayData[value.toInt()].weekday);
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
                            weekdayData.asMap().entries.map((entry) {
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

class _TimeSlotAnalysisPanel extends ConsumerWidget {
  const _TimeSlotAnalysisPanel({required this.analysisPeriod});

  final int analysisPeriod;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 選択された期間に基づいてフィルタリングされたデータを取得
    final timeSlotDataAsync = ref.watch(
      filteredTimeSlotFrequencyProvider(analysisPeriod),
    );

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
        final periodText = _getPeriodText(analysisPeriod: analysisPeriod);

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

/// 選択されている期間に応じたテキストを返す
String _getPeriodText({required int analysisPeriod}) {
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
