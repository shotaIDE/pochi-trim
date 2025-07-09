import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pochi_trim/ui/feature/analysis/analysis_period.dart';
import 'package:pochi_trim/ui/feature/analysis/analysis_presenter.dart';
import 'package:pochi_trim/ui/feature/analysis/bar_chart_touched_position.dart';
import 'package:pochi_trim/ui/feature/analysis/statistics.dart';
import 'package:pochi_trim/ui/feature/pro/upgrade_to_pro_screen.dart';

/// 分析画面
///
/// 家事の実行頻度や曜日ごとの頻度分析を表示する
class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  static const name = 'AnalysisScreen';

  static MaterialPageRoute<AnalysisScreen> route() =>
      MaterialPageRoute<AnalysisScreen>(
        builder: (_) => const AnalysisScreen(),
        settings: const RouteSettings(name: name),
      );

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
          error: (error, stackTrace) => Center(
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

  // Proマークのスタイル定数
  static const _proMarkSpacing = 4.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysisPeriod = ref.watch(currentAnalysisPeriodProvider);
    final dropdownButton = FutureBuilder(
      future: ref.watch(analysisPeriodDropdownItemsProvider.future),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            width: 150,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final dropdownItems = snapshot.data!;

        return DropdownButton<AnalysisPeriodDropdownValue>(
          value: _getPeriodValue(analysisPeriod),
          items: _buildDropdownItemsSync(dropdownItems, context),
          onChanged: (value) async {
            if (value == null) {
              return;
            }

            final selectedItem = dropdownItems.firstWhere(
              (item) => item.value == value,
            );

            if (selectedItem.unavailableBecauseProFeature) {
              await _showProUpgradeDialog(context);
              return;
            }

            final period = _getPeriod(value);
            ref.read(currentAnalysisPeriodProvider.notifier).setPeriod(period);
          },
        );
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
        dropdownButton,
        periodText,
      ],
    );
  }

  AnalysisPeriodDropdownValue _getPeriodValue(AnalysisPeriod analysisPeriod) {
    switch (analysisPeriod) {
      case AnalysisPeriodToday _:
        return AnalysisPeriodDropdownValue.today;
      case AnalysisPeriodYesterday _:
        return AnalysisPeriodDropdownValue.yesterday;
      case AnalysisPeriodCurrentWeek _:
        return AnalysisPeriodDropdownValue.currentWeek;
      case AnalysisPeriodCurrentMonth _:
        return AnalysisPeriodDropdownValue.currentMonth;
      case AnalysisPeriodPastWeek _:
        return AnalysisPeriodDropdownValue.pastWeek;
      case AnalysisPeriodPastTwoWeeks _:
        return AnalysisPeriodDropdownValue.pastTwoWeeks;
      case AnalysisPeriodPastMonth _:
        return AnalysisPeriodDropdownValue.pastMonth;
    }
  }

  AnalysisPeriod _getPeriod(AnalysisPeriodDropdownValue value) {
    final current = DateTime.now();

    switch (value) {
      case AnalysisPeriodDropdownValue.today:
        return AnalysisPeriodTodayGenerator.fromCurrentDate(current);
      case AnalysisPeriodDropdownValue.yesterday:
        return AnalysisPeriodYesterdayGenerator.fromCurrentDate(current);
      case AnalysisPeriodDropdownValue.currentWeek:
        return AnalysisPeriodCurrentWeekGenerator.fromCurrentDate(current);
      case AnalysisPeriodDropdownValue.currentMonth:
        return AnalysisPeriodCurrentMonthGenerator.fromCurrentDate(current);
      case AnalysisPeriodDropdownValue.pastWeek:
        return AnalysisPeriodPastWeekGenerator.fromCurrentDate(current);
      case AnalysisPeriodDropdownValue.pastTwoWeeks:
        return AnalysisPeriodPastTwoWeeksGenerator.fromCurrentDate(current);
      case AnalysisPeriodDropdownValue.pastMonth:
        return AnalysisPeriodPastMonthGenerator.fromCurrentDate(current);
    }
  }

  List<DropdownMenuItem<AnalysisPeriodDropdownValue>> _buildDropdownItemsSync(
    List<AnalysisPeriodDropdownItem> dropdownItems,
    BuildContext context,
  ) {
    return dropdownItems.map((item) {
      final shouldShowProMark = item.unavailableBecauseProFeature;
      final label = _getLabelForValue(item.value);

      return DropdownMenuItem<AnalysisPeriodDropdownValue>(
        value: item.value,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            if (shouldShowProMark) ...[
              const SizedBox(width: _proMarkSpacing),
              const _ProMark(),
            ],
          ],
        ),
      );
    }).toList();
  }

  String _getLabelForValue(AnalysisPeriodDropdownValue value) {
    switch (value) {
      case AnalysisPeriodDropdownValue.today:
        return '今日';
      case AnalysisPeriodDropdownValue.yesterday:
        return '昨日';
      case AnalysisPeriodDropdownValue.currentWeek:
        return '今週';
      case AnalysisPeriodDropdownValue.currentMonth:
        return '今月';
      case AnalysisPeriodDropdownValue.pastWeek:
        return '過去1週間';
      case AnalysisPeriodDropdownValue.pastTwoWeeks:
        return '過去2週間';
      case AnalysisPeriodDropdownValue.pastMonth:
        return '過去1ヶ月';
    }
  }

  Future<void> _showProUpgradeDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pro版限定機能'),
        content: const Text('1週間を超える期間の分析はPro版でのみ利用できます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(UpgradeToProScreen.route());
            },
            child: const Text('Pro版にアップグレード'),
          ),
        ],
      ),
    );
  }
}

class _WeekdayAnalysisPanel extends ConsumerStatefulWidget {
  const _WeekdayAnalysisPanel();

  @override
  ConsumerState<_WeekdayAnalysisPanel> createState() =>
      _WeekdayAnalysisPanelState();
}

class _WeekdayAnalysisPanelState extends ConsumerState<_WeekdayAnalysisPanel> {
  BarChartTouchedPosition? _touchedPosition;

  @override
  Widget build(BuildContext context) {
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

        if (statistics.houseWorkLegends.isEmpty) {
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

        final weekdayFrequencies = statistics.weekdayFrequencies;

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
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                tooltipMargin: -40,
                getTooltipColor: (_) =>
                    Theme.of(context).colorScheme.surfaceContainerHigh,
                getTooltipItem:
                    (
                      BarChartGroupData group,
                      int groupIndex,
                      BarChartRodData rod,
                      int rodIndex,
                    ) {
                      final touchedPosition = _touchedPosition;
                      if (touchedPosition == null) {
                        return null;
                      }

                      final touchedFrequency =
                          weekdayFrequencies[touchedPosition.groupIndex];
                      final totalCount = touchedFrequency.totalCount;
                      final touchedHouseWorkFrequency = touchedFrequency
                          .houseWorkFrequencies[touchedPosition.stackItemIndex];
                      final touchedHouseWorkName =
                          touchedHouseWorkFrequency.houseWork.title;
                      final touchedHouseWorkCount =
                          touchedHouseWorkFrequency.count;

                      return BarTooltipItem(
                        '$touchedHouseWorkCount / $totalCount\n'
                        '$touchedHouseWorkName / 合計',
                        Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      );
                    },
              ),
              handleBuiltInTouches: true,
              touchCallback: (FlTouchEvent event, barTouchResponse) {
                if (event is! FlTapDownEvent) {
                  return;
                }

                final spot = barTouchResponse?.spot;
                if (spot == null) {
                  setState(() {
                    _touchedPosition = null;
                  });

                  return;
                }

                final touchedBarGroupIndex = spot.touchedBarGroupIndex;
                final touchedRodDataIndex = spot.touchedRodDataIndex;
                final touchedStackItemIndex = spot.touchedStackItemIndex;

                setState(() {
                  _touchedPosition = BarChartTouchedPosition(
                    groupIndex: touchedBarGroupIndex,
                    rodDataIndex: touchedRodDataIndex,
                    stackItemIndex: touchedStackItemIndex,
                  );
                });

                debugPrint(
                  'Event: $event, '
                  'TouchedBarGroup: $touchedBarGroupIndex, '
                  'TouchedRodData: $touchedRodDataIndex, '
                  'TouchedStackItem: $touchedStackItemIndex',
                );
              },
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
            barGroups: weekdayFrequencies.asMap().entries.map((entry) {
              final index = entry.key;
              final frequency = entry.value;

              // 家事ごとの色を一貫させるために、houseWorkIdに基づいて色を割り当てる
              final rodStackItems = <BarChartRodStackItem>[];
              double fromY = 0;

              // 表示されている家事だけを処理
              for (final freq in frequency.houseWorkFrequencies) {
                final toY = fromY + freq.count;

                rodStackItems.add(BarChartRodStackItem(fromY, toY, freq.color));

                fromY = toY;
              }

              final List<int> showingTooltipIndicators;
              final touchedPosition = _touchedPosition;
              if (touchedPosition != null &&
                  touchedPosition.groupIndex == index) {
                showingTooltipIndicators = [touchedPosition.rodDataIndex];
              } else {
                showingTooltipIndicators = [];
              }

              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: frequency.totalCount.toDouble(),
                    width: 20,
                    color: Colors.transparent,
                    rodStackItems: rodStackItems,
                    borderRadius: BorderRadius.zero,
                  ),
                ],
                showingTooltipIndicators: showingTooltipIndicators,
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
                          .focusOrUnfocus(houseWorkId: houseWorkId);
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

        if (statistics.houseWorkLegends.isEmpty) {
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

        final timeSlotFrequencies = statistics.timeSlotFrequencies;

        final barChart = BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: timeSlotFrequencies.isNotEmpty
                ? timeSlotFrequencies
                      .map((e) => e.totalCount.toDouble())
                      .reduce((a, b) => a > b ? a : b)
                : 0,
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
            barGroups: timeSlotFrequencies.asMap().entries.map((entry) {
              final index = entry.key;
              final data = entry.value;

              // 家事ごとの色を一貫させるために、houseWorkIdに基づいて色を割り当てる
              final rodStackItems = <BarChartRodStackItem>[];
              double fromY = 0;

              // 表示されている家事だけを処理
              for (final freq in data.houseWorkFrequencies) {
                final toY = fromY + freq.count;

                rodStackItems.add(BarChartRodStackItem(fromY, toY, freq.color));

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
                          .focusOrUnfocus(houseWorkId: houseWorkId);
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
            children: legends.map((legend) {
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
                        Container(width: 16, height: 16, color: legend.color),
                        const SizedBox(width: 4),
                        Text(
                          legend.houseWork.title,
                          style: TextStyle(
                            fontSize: 12,
                            decoration: legend.isVisible
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

/// Pro版限定機能を示すアイコン
class _ProMark extends StatelessWidget {
  const _ProMark();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.workspace_premium,
      size: 16,
      color: Colors.amber,
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
