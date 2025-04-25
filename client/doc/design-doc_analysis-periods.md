# 分析期間選択 UI 実装計画

## 概要

現在の分析画面には「分析方式」（家事の頻度分析と曜日ごとの頻度分析）の切り替え UI はあるが、分析期間（今日・今週・今月）を選択する UI がない。画面仕様書の要件に基づき、分析期間選択 UI を実装する。

## 設計方針

### UI デザイン

- セレクトボックスを使用
- 「今日」「今週」「今月」の 3 つの選択肢を持つ
- 分析方式切り替え UI の上部に配置

### 状態管理

- 現在は`_analysisMode`のローカル変数で分析方式を管理
- 同様に`_analysisPeriod`のローカル変数を追加
- 期間の種類は以下の 3 つ
  - 0: 今日
  - 1: 今週
  - 2: 今月

### データフィルタリング

- 現在のプロバイダー(`workLogsForAnalysisProvider`)は、期間によるフィルタリングをしていない
- 期間選択に応じて異なるデータセットを提供する新しいプロバイダーを実装
- 選択された期間に基づいて WorkLog データをフィルタリングするロジックを追加

## 実装計画

### 1. 状態変数と UI コンポーネントの追加

- `_AnalysisScreenState`クラスに`_analysisPeriod`変数を追加
- 期間選択用の`SegmentedButton`ウィジェットを実装する`_buildAnalysisPeriodSwitcher()`メソッドを追加

### 2. プロバイダーの修正

- `workLogsForAnalysisProvider`を拡張して期間パラメータを受け取るようにする
- または、既存プロバイダーを利用した新しい`filteredWorkLogsProvider`を作成

### 3. フィルタリングロジックの実装

- 「今日」: 現在日の 00:00 から 23:59 までのログのみ表示
- 「今週」: 現在週の月曜日 00:00 から日曜日 23:59 までのログのみ表示
- 「今月」: 現在月の 1 日 00:00 から末日 23:59 までのログのみ表示

### 4. UI の更新

- `build`メソッドの Column 内に期間選択 UI を追加
- 既存の分析表示ウィジェットが選択された期間に基づいてデータを表示するよう修正

## コード変更予定箇所

1. `_AnalysisScreenState`クラス

```dart
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

  // ...
}
```

2. 期間選択 UI メソッド

```dart
/// 分析期間の切り替えUIを構築
Widget _buildAnalysisPeriodSwitcher() {
  return Padding(
    padding: const EdgeInsets.all(16),
    child: SegmentedButton<int>(
      segments: const [
        ButtonSegment<int>(value: 0, label: Text('今日')),
        ButtonSegment<int>(value: 1, label: Text('今週')),
        ButtonSegment<int>(value: 2, label: Text('今月')),
      ],
      selected: {_analysisPeriod},
      onSelectionChanged: (Set<int> newSelection) {
        setState(() {
          _analysisPeriod = newSelection.first;
        });
      },
    ),
  );
}
```

3. フィルタリング機能付きプロバイダー

```dart
// 期間で絞り込まれた家事ログの取得と分析のためのプロバイダー
final filteredWorkLogsProvider = FutureProvider.family<List<WorkLog>, int>((
  ref,
  period,
) async {
  final workLogRepository = ref.watch(workLogRepositoryProvider);
  final houseId = ref.watch(currentHouseIdProvider);
  final allWorkLogs = await workLogRepository.getAll(houseId);

  // 現在時刻を取得
  final now = DateTime.now();

  // 期間によるフィルタリング
  switch (period) {
    case 0: // 今日
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1)).subtract(const Duration(microseconds: 1));
      return allWorkLogs.where((log) =>
        log.completedAt.isAfter(startOfDay) &&
        log.completedAt.isBefore(endOfDay)
      ).toList();

    case 1: // 今週
      // 週の開始は月曜日、終了は日曜日とする
      final currentWeekday = now.weekday;
      final startOfWeek = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: currentWeekday - 1));
      final endOfWeek = startOfWeek
          .add(const Duration(days: 7))
          .subtract(const Duration(microseconds: 1));
      return allWorkLogs.where((log) =>
        log.completedAt.isAfter(startOfWeek) &&
        log.completedAt.isBefore(endOfWeek)
      ).toList();

    case 2: // 今月
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = (now.month < 12)
          ? DateTime(now.year, now.month + 1, 1)
          : DateTime(now.year + 1, 1, 1);
      final lastDayOfMonth = endOfMonth.subtract(const Duration(microseconds: 1));
      return allWorkLogs.where((log) =>
        log.completedAt.isAfter(startOfMonth) &&
        log.completedAt.isBefore(lastDayOfMonth)
      ).toList();

    default:
      return allWorkLogs;
  }
});
```

4. UI の修正

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('分析'),
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
          child:
              _analysisMode == 0
                  ? _buildFrequencyAnalysis(_analysisPeriod)
                  : _buildWeekdayAnalysis(_analysisPeriod),
        ),
      ],
    ),
  );
}
```

## テスト計画

1. 各期間（今日・今週・今月）を選択した際に、対象期間のデータのみが表示されることを確認
2. 表示されるデータが正確に期間内のものであるか確認
3. 期間を切り替えた際に、UI が適切に更新されることを確認
4. データが存在しない期間を選択した際に、適切なメッセージが表示されることを確認

## 実装スケジュール

1. プロバイダーの拡張/新規作成
2. 期間選択 UI の実装
3. UI とプロバイダーの連携
4. テスト
