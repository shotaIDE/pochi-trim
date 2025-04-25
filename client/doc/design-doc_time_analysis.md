# 時間帯による家事分析機能の追加設計

## 概要

「分析」画面に新たな分析方式として「時間帯による分析」を追加します。
これにより、ユーザーは家事がどの時間帯に多く行われているかを視覚的に把握できるようになります。

## 変更前後の仕様

### 変更前

```
- 分析方式の切り替え UI を表示する
  - 分析方式は以下の 2 つを表示する
    - 家事の頻度分析
      - 家事の実行頻度が高い順で表示する
    - 家事の曜日ごとの頻度分析
      - 家事の実行頻度を曜日ごとに表示する
```

### 変更後

```
- 分析方式の切り替え UI を表示する
  - 分析方式は以下を表示する
    - 家事の頻度分析
      - 家事の実行頻度が高い順で表示する
    - 家事の曜日ごとの頻度分析
      - 家事の実行頻度を曜日ごとに表示する
    - 時間帯による分析
      - 家事の実行回数を 3 時間帯ごとに表示する
      - 家事ごとの積み上げ棒グラフを表示する
```

## 実装計画

### 1. データモデルの追加

家事ごとの時間帯分析のためのデータモデルを追加します。

```dart
// 時間帯別の家事実行頻度のためのデータクラス
class TimeSlotFrequency {
  TimeSlotFrequency({
    required this.timeSlot,
    required this.houseWorkFrequencies,
    required this.totalCount,
  });
  final String timeSlot;          // 時間帯の表示名（例：「0-3時」）
  final List<HouseWorkFrequency> houseWorkFrequencies;  // その時間帯での家事ごとの実行回数
  final int totalCount;           // その時間帯の合計実行回数
}
```

### 2. データプロバイダーの追加

時間帯ごとの家事実行頻度を取得するプロバイダーを追加します。

```dart
// 時間帯ごとの家事実行頻度を取得するプロバイダー（期間フィルタリング付き）
final FutureProviderFamily<List<TimeSlotFrequency>, int> filteredTimeSlotFrequencyProvider =
    FutureProvider.family<List<TimeSlotFrequency>, int>((ref, period) async {
      // フィルタリングされた家事ログのデータを待機
      final workLogs = await ref.watch(filteredWorkLogsProvider(period).future);
      final houseWorkRepository = ref.watch(houseWorkRepositoryProvider);
      final houseId = ref.watch(currentHouseIdProvider);

      // 時間帯の定義（3時間ごと）
      final timeSlots = [
        '0-3時', '3-6時', '6-9時', '9-12時',
        '12-15時', '15-18時', '18-21時', '21-24時'
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
```

### 3. UI 変更

1. 分析方式の切り替え UI に「時間帯による分析」オプションを追加します。
2. 時間帯ごとの分析結果を表示するウィジェット `_buildTimeSlotAnalysis()` を実装します。

#### 分析方式切り替え UI の変更

```dart
Widget _buildAnalysisModeSwitcher() {
  return Padding(
    padding: const EdgeInsets.all(16),
    child: SegmentedButton<int>(
      segments: const [
        ButtonSegment<int>(value: 0, label: Text('家事の頻度分析')),
        ButtonSegment<int>(value: 1, label: Text('曜日ごとの頻度分析')),
        ButtonSegment<int>(value: 2, label: Text('時間帯による分析')), // 追加
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
```

#### 分析結果表示部分の変更

```dart
Expanded(
  child: () {
    switch (_analysisMode) {
      case 0:
        return _buildFrequencyAnalysis();
      case 1:
        return _buildWeekdayAnalysis();
      case 2:
        return _buildTimeSlotAnalysis(); // 追加
      default:
        return _buildFrequencyAnalysis();
    }
  }(),
),
```

#### 時間帯分析表示ウィジェットの実装

```dart
/// 時間帯ごとの分析を表示するウィジェットを構築
Widget _buildTimeSlotAnalysis() {
  return Consumer(
    builder: (context, ref, child) {
      // 選択された期間に基づいてフィルタリングされたデータを取得
      final timeSlotDataAsync = ref.watch(
        filteredTimeSlotFrequencyProvider(_analysisPeriod),
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
          final periodText = _getPeriodText();

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
                    child: ListView.builder(
                      itemCount: timeSlotData.length,
                      itemBuilder: (context, index) {
                        final item = timeSlotData[index];

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

                        if (item.totalCount == 0) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.timeSlot),
                                const SizedBox(height: 4),
                                Container(
                                  height: 24,
                                  color: Colors.grey.withOpacity(0.2),
                                  child: const Center(
                                    child: Text('データなし', style: TextStyle(color: Colors.grey)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(item.timeSlot),
                                  Text('合計: ${item.totalCount}回'),
                                ],
                              ),
                              const SizedBox(height: 4),
                              SizedBox(
                                height: 24,
                                child: Row(
                                  children: [
                                    // 家事ごとの積み上げ棒グラフ
                                    ...item.houseWorkFrequencies.asMap().entries.map((entry) {
                                      final i = entry.key;
                                      final workFreq = entry.value;
                                      final ratio = workFreq.count / item.totalCount.toDouble();

                                      return Expanded(
                                        flex: (ratio * 100).toInt(),
                                        child: Container(
                                          height: 24,
                                          color: colors[i % colors.length],
                                        ),
                                      );
                                    }).toList(),

                                    // データが少ない場合、残りのスペースを埋める透明コンテナ
                                    if (item.houseWorkFrequencies.isEmpty)
                                      Expanded(
                                        child: Container(
                                          height: 24,
                                          color: Colors.grey.withOpacity(0.2),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              // 凡例の表示
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: item.houseWorkFrequencies.asMap().entries.map((entry) {
                                  final i = entry.key;
                                  final workFreq = entry.value;

                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        color: colors[i % colors.length],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${workFreq.houseWork.title}: ${workFreq.count}回',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  );
                                }).toList(),
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
        error: (error, stackTrace) => Center(
          child: Text('エラーが発生しました: $error', textAlign: TextAlign.center),
        ),
      );
    },
  );
}
```

## テスト計画

1. 単体テスト：

   - `TimeSlotFrequency` クラスのテスト
   - `filteredTimeSlotFrequencyProvider` のテスト
   - 時間帯によって家事ログが正しく分類されるかのテスト

2. 統合テスト：

   - 分析方式の切り替えが正しく動作するかのテスト
   - 異なる分析期間での時間帯分析の結果が正しいかのテスト

3. UI テスト：
   - 積み上げ棒グラフが正しく表示されるかのテスト
   - 凡例が正しく表示されるかのテスト
   - データがない場合の表示のテスト

## 実装スケジュール

1. データモデルとプロバイダーの実装 (1 日)
2. UI 部分の実装 (2 日)
3. テストの作成と実行 (1 日)
4. バグ修正と調整 (1 日)

合計: 5 日間

## 注意点と検討事項

1. グラフ表示のパフォーマンスに注意する必要があります。大量のデータがある場合は、パフォーマンス最適化を検討しましょう。
2. 色分けは、利用可能な家事数が多い場合に区別が難しくなることがあります。上位 8 つ程度に制限するか、または代替の表示方法を検討する必要があるかもしれません。
3. 時間帯の区分は、ユーザーニーズに応じて調整可能にすることも検討しましょう。
