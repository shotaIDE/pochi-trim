# 家事所要時間分析機能の要件定義

## 概要

家事にかかった時間をログに記録し、所要時間の分析を行う機能を実装する。これにより、ユーザーは家事の効率性を把握し、時間管理の改善に役立てることができる。

## 現状の実装

現在のシステムでは以下の機能が実装されている：

1. **家事ログ（WorkLog）モデル**

   - `id`: 家事ログの ID
   - `houseWorkId`: 関連する家事の ID
   - `completedAt`: 完了時刻（DateTime）
   - `completedBy`: 実行したユーザーの ID

2. **分析機能**

   - 家事の頻度分析
   - 曜日ごとの頻度分析
   - 時間帯ごとの頻度分析
   - 期間フィルタリング機能

3. **家事完了登録**
   - 家事アイテムのタップで完了登録
   - デバウンス機能（3 秒間隔）

## 機能要件

### 1. 家事開始・完了の記録機能

#### 1.1 家事開始の記録

- 家事アイテムをタップした際に、開始時刻を記録する
- 既に開始中の家事がある場合は、その家事を完了として記録してから新しい家事を開始する
- 開始中の家事は視覚的に識別できるように表示する

#### 1.2 家事完了の記録

- 家事アイテムを再度タップした際に、完了時刻を記録する
- 開始時刻と完了時刻から所要時間を計算し、保存する
- 完了後は通常の状態に戻る

#### 1.3 所要時間の計算

- 所要時間 = 完了時刻 - 開始時刻
- 所要時間は分単位で記録する（小数点以下 1 桁まで）
- 所要時間が負の値になる場合は、エラーとして処理する

### 2. 所要時間分析機能

#### 2.1 基本統計情報の表示

- **平均所要時間**: 各家事の平均所要時間を表示
- **最短所要時間**: 各家事の最短所要時間を表示
- **最長所要時間**: 各家事の最長所要時間を表示
- **所要時間の標準偏差**: 所要時間のばらつきを表示

#### 2.2 所要時間の傾向分析

- **期間別平均所要時間**: 週別、月別の平均所要時間の推移
- **曜日別平均所要時間**: 曜日ごとの平均所要時間
- **時間帯別平均所要時間**: 時間帯ごとの平均所要時間

#### 2.3 所要時間の可視化

- **ヒストグラム**: 所要時間の分布を表示
- **時系列グラフ**: 所要時間の推移を表示
- **箱ひげ図**: 所要時間の統計情報を視覚的に表示

### 3. 所要時間の比較機能

#### 3.1 家事間の比較

- 異なる家事の所要時間を比較できる
- 所要時間の長い家事と短い家事を識別できる

#### 3.2 期間比較

- 過去の期間と現在の期間の所要時間を比較できる
- 改善傾向や悪化傾向を把握できる

#### 3.3 ユーザー間比較（将来的な機能）

- 同じ家事の所要時間を家族間で比較できる（Pro 機能として検討）

## データ要件

### 1. 拡張された家事ログモデル（WorkLog）

```dart
class WorkLog {
  String id;
  String houseWorkId;
  DateTime? startedAt;        // 開始時刻（新規追加）
  DateTime completedAt;       // 完了時刻（既存）
  String completedBy;
  int? durationMinutes;       // 所要時間（分）（新規追加）
}
```

### 2. 所要時間分析用のモデル

```dart
class DurationAnalysis {
  String houseWorkId;
  double averageDuration;     // 平均所要時間（分）
  double minDuration;         // 最短所要時間（分）
  double maxDuration;         // 最長所要時間（分）
  double standardDeviation;   // 標準偏差
  int totalCount;            // 記録回数
}

class DurationTrend {
  String houseWorkId;
  DateTime periodStart;
  DateTime periodEnd;
  double averageDuration;
  int count;
}
```

### 3. データベース設計

#### 3.1 Firestore コレクション構造

```
houses/{houseId}/houseWorks/{houseWorkId}/workLogs/{workLogId}
```

#### 3.2 インデックス要件

- `houseWorkId` + `completedAt` の複合インデックス
- `houseWorkId` + `startedAt` の複合インデックス（新規追加）

## UI 要件

### 1. 家事アイテムの表示

#### 1.1 通常状態

- 家事の名前とアイコンを表示
- タップ可能であることを示す視覚的インジケーター

#### 1.2 開始中状態

- 開始中の家事は背景色を変更して表示
- 開始時刻を表示
- 進行中のインジケーター（アニメーション）を表示

#### 1.3 完了状態

- 完了時の所要時間を一時的に表示
- 完了アニメーションを表示

### 2. 分析画面の拡張

#### 2.1 所要時間分析タブの追加

- 既存の分析画面に「所要時間」タブを追加
- 所要時間の基本統計情報を表示

#### 2.2 所要時間の詳細分析画面

- 各家事の所要時間詳細を表示
- グラフやチャートで可視化
- 期間フィルタリング機能

#### 2.3 所要時間の比較画面

- 複数の家事の所要時間を比較表示
- 期間比較機能

### 3. 設定画面の拡張

#### 3.1 所要時間記録の設定

- 所要時間記録の有効/無効切り替え
- 所要時間の単位設定（分/時間）
- 所要時間の表示精度設定

## 技術要件

### 1. 状態管理

#### 1.1 現在進行中の家事の管理

```dart
@riverpod
class CurrentActiveHouseWork extends _$CurrentActiveHouseWork {
  @override
  String? build() => null;

  void start(String houseWorkId) {
    state = houseWorkId;
  }

  void stop() {
    state = null;
  }
}
```

#### 1.2 所要時間分析の状態管理

```dart
@riverpod
Future<List<DurationAnalysis>> durationAnalysis(Ref ref) async {
  // 所要時間分析の実装
}

@riverpod
Future<List<DurationTrend>> durationTrends(Ref ref) async {
  // 所要時間傾向分析の実装
}
```

### 2. サービス層

#### 2.1 所要時間計算サービス

```dart
class DurationCalculationService {
  int calculateDurationMinutes(DateTime start, DateTime end);
  double calculateAverageDuration(List<int> durations);
  double calculateStandardDeviation(List<int> durations);
}
```

#### 2.2 所要時間分析サービス

```dart
class DurationAnalysisService {
  Future<List<DurationAnalysis>> analyzeDurations(String houseWorkId, DateTime from, DateTime to);
  Future<List<DurationTrend>> analyzeTrends(String houseWorkId, AnalysisPeriod period);
}
```

### 3. リポジトリ層の拡張

#### 3.1 WorkLogRepository の拡張

```dart
class WorkLogRepository {
  Future<void> addWithDuration(AddWorkLogWithDurationArgs args);
  Future<List<WorkLog>> getWithDuration(String houseWorkId, DateTime from, DateTime to);
}
```

## 影響範囲

### 1. 新規作成が必要なファイル

1. **モデル**

   - `client/lib/data/model/duration_analysis.dart`
   - `client/lib/data/model/duration_trend.dart`
   - `client/lib/data/model/add_work_log_with_duration_args.dart`

2. **サービス**

   - `client/lib/data/service/duration_calculation_service.dart`
   - `client/lib/data/service/duration_analysis_service.dart`

3. **UI**

   - `client/lib/ui/feature/analysis/duration_analysis_screen.dart`
   - `client/lib/ui/feature/analysis/duration_analysis_presenter.dart`
   - `client/lib/ui/feature/analysis/duration_chart_widget.dart`

4. **テスト**
   - `client/test/services/duration_calculation_service_test.dart`
   - `client/test/services/duration_analysis_service_test.dart`
   - `client/test/ui/feature/analysis/duration_analysis_presenter_test.dart`

### 2. 修正が必要なファイル

1. **既存モデル**

   - `client/lib/data/model/work_log.dart` - 所要時間フィールドの追加

2. **既存サービス**

   - `client/lib/data/service/work_log_service.dart` - 所要時間記録機能の追加

3. **既存リポジトリ**

   - `client/lib/data/repository/work_log_repository.dart` - 所要時間関連のクエリ追加

4. **既存 UI**

   - `client/lib/ui/feature/home/home_screen.dart` - 開始中状態の表示
   - `client/lib/ui/feature/home/home_presenter.dart` - 所要時間記録機能
   - `client/lib/ui/feature/analysis/analysis_screen.dart` - 所要時間タブの追加

5. **インフラ**
   - `infra/module/firestore/main.tf` - 新しいインデックスの追加

## 制約事項

### 1. データ整合性

- 開始時刻と完了時刻の整合性を保つ必要がある
- 同時に複数の家事を開始できないようにする

### 2. パフォーマンス

- 大量のログデータに対する分析処理の最適化
- リアルタイム更新の負荷軽減

### 3. ユーザビリティ

- 所要時間記録の手間を最小限に抑える
- 直感的な操作で所要時間を記録できる

### 4. データ精度

- 時刻の精度は分単位とする
- 所要時間の計算誤差を最小限に抑える

## 将来の拡張可能性

### 1. Pro 機能としての拡張

- 詳細な所要時間分析
- 所要時間の予測機能
- 所要時間の最適化提案

### 2. 外部連携

- カレンダーアプリとの連携
- 時間管理アプリとの連携

### 3. 機械学習機能

- 所要時間の異常検知
- 所要時間の最適化提案
- 家事の効率性スコアリング
