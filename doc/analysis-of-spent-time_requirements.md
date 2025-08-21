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

### 1. 家事所要時間記録機能

#### 1.1 家事のデフォルト所要時間設定

- 家事作成・編集時にデフォルトの所要時間（分）を設定できる
- デフォルト所要時間は家事の基本情報として保存される
- デフォルト所要時間は 1, 2, 3, 5, 10, 15, 20, 30, 45, 60 分から選択可能
- 手動入力も可能とする（1 分以上、最大 120 分（2 時間）まで）

#### 1.2 家事ログ登録時の所要時間記録

- 家事アイテムをタップした際に、家事ログを登録する
- 登録時は家事のデフォルト所要時間が自動的に記録される
- 既存のデバウンス機能（3 秒間隔）は維持する

#### 1.3 家事ログの所要時間編集

- 家事ログの編集画面から、各ログの所要時間を編集できる
- 所要時間は 1, 2, 3, 5, 10, 15, 20, 30, 45, 60 分から選択可能
- 手動入力も可能とする（1 分以上、最大 120 分（2 時間）まで）
- 編集後は家事ログの所要時間が更新される

### 2. 所要時間分析機能

#### 2.1 所要時間の傾向分析

- **期間別平均所要時間**: 週別、月別の平均所要時間の推移
- **曜日別平均所要時間**: 曜日ごとの平均所要時間
- **時間帯別平均所要時間**: 時間帯ごとの平均所要時間

## データ要件

### 1. 拡張された家事モデル（HouseWork）

```dart
class HouseWork {
  String id;
  String title;
  String icon;
  DateTime createdAt;
  String createdBy;
  int? defaultDurationMinutes;  // デフォルト所要時間（分）（新規追加）
}
```

### 2. 拡張された家事ログモデル（WorkLog）

```dart
class WorkLog {
  String id;
  String houseWorkId;
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
- `defaultDurationMinutes` の単一インデックス（新規追加）

## UI 要件

### 1. 家事アイテムの表示

#### 1.1 通常状態

- 家事の名前とアイコンを表示
- デフォルト所要時間を表示（設定されている場合）
- タップ可能であることを示す視覚的インジケーター

#### 1.2 家事ログ登録時

- 登録成功時のフィードバックを表示
- 登録された所要時間を一時的に表示
- 既存のスナックバー通知を維持

### 2. 家事作成・編集画面の拡張

#### 2.1 デフォルト所要時間設定

- 家事作成・編集画面に所要時間設定セクションを追加
- プリセット選択（1, 2, 3, 5, 10, 15, 20, 30, 45, 60 分）と手動入力の両方を提供
- 手動入力時は 1 分以上、最大 1440 分（24 時間）までの制限を設ける
- 設定値のバリデーション機能

### 3. 家事ログ編集画面の拡張

#### 3.1 所要時間編集機能

- 既存の家事ログ編集画面に所要時間編集セクションを追加
- プリセット選択（1, 2, 3, 5, 10, 15, 20, 30, 45, 60 分）と手動入力の両方を提供
- 手動入力時は 1 分以上、最大 1440 分（24 時間）までの制限を設ける
- 現在の所要時間を初期値として表示
- 編集後の保存・キャンセル機能

### 4. 分析画面の拡張

#### 4.1 所要時間分析タブの追加

- 既存の分析画面に「所要時間」タブを追加
- 所要時間の基本統計情報を表示

#### 4.2 所要時間の詳細分析画面

- 各家事の所要時間詳細を表示
- グラフやチャートで可視化
- 期間フィルタリング機能

#### 4.3 所要時間の比較画面

- 複数の家事の所要時間を比較表示
- 期間比較機能

### 5. 設定画面の拡張

#### 5.1 所要時間記録の設定

- 所要時間記録の有効/無効切り替え
- 所要時間の単位設定（分/時間）
- 所要時間の表示精度設定

## 技術要件

### 1. 状態管理

#### 1.1 所要時間設定の管理

```dart
@riverpod
class DurationSettings extends _$DurationSettings {
  @override
  DurationSettingsState build() {
    return const DurationSettingsState();
  }

  void updateDefaultDuration(String houseWorkId, int durationMinutes) {
    // 家事のデフォルト所要時間を更新
  }

  void updateWorkLogDuration(String workLogId, int durationMinutes) {
    // 家事ログの所要時間を更新
  }
}

class DurationSettingsState {
  final Map<String, int> defaultDurations;
  final Map<String, int> workLogDurations;

  const DurationSettingsState({
    this.defaultDurations = const {},
    this.workLogDurations = const {},
  });
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

#### 2.1 所要時間設定サービス

```dart
class DurationSettingsService {
  List<int> getPresetDurations();  // プリセット所要時間リスト
  bool isValidDuration(int minutes);  // 所要時間の妥当性チェック
  int getDefaultDuration(String houseWorkId);  // 家事のデフォルト所要時間取得
  Future<void> setDefaultDuration(String houseWorkId, int minutes);  // デフォルト所要時間設定
  Future<void> updateWorkLogDuration(String workLogId, int minutes);  // 家事ログ所要時間更新
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

#### 3.1 HouseWorkRepository の拡張

```dart
class HouseWorkRepository {
  Future<void> updateDefaultDuration(String houseWorkId, int durationMinutes);
  Future<List<HouseWork>> getWithDefaultDuration();
}
```

#### 3.2 WorkLogRepository の拡張

```dart
class WorkLogRepository {
  Future<void> updateDuration(String workLogId, int durationMinutes);
  Future<List<WorkLog>> getWithDuration(String houseWorkId, DateTime from, DateTime to);
}
```

## 影響範囲

### 1. 新規作成が必要なファイル

1. **モデル**

   - `client/lib/data/model/duration_analysis.dart`
   - `client/lib/data/model/duration_trend.dart`
   - `client/lib/data/model/duration_settings.dart`

2. **サービス**

   - `client/lib/data/service/duration_settings_service.dart`
   - `client/lib/data/service/duration_analysis_service.dart`

3. **UI**

   - `client/lib/ui/feature/analysis/duration_analysis_screen.dart`
   - `client/lib/ui/feature/analysis/duration_analysis_presenter.dart`
   - `client/lib/ui/feature/analysis/duration_chart_widget.dart`

4. **テスト**
   - `client/test/services/duration_settings_service_test.dart`
   - `client/test/services/duration_analysis_service_test.dart`
   - `client/test/ui/feature/analysis/duration_analysis_presenter_test.dart`

### 2. 修正が必要なファイル

1. **既存モデル**

   - `client/lib/data/model/house_work.dart` - デフォルト所要時間フィールドの追加
   - `client/lib/data/model/work_log.dart` - 所要時間フィールドの追加

2. **既存サービス**

   - `client/lib/data/service/work_log_service.dart` - デフォルト所要時間での記録機能の追加

3. **既存リポジトリ**

   - `client/lib/data/repository/house_work_repository.dart` - デフォルト所要時間の更新機能追加
   - `client/lib/data/repository/work_log_repository.dart` - 所要時間更新機能の追加

4. **既存 UI**

   - `client/lib/ui/feature/home/home_screen.dart` - デフォルト所要時間の表示
   - `client/lib/ui/feature/home/home_presenter.dart` - デフォルト所要時間での記録機能
   - `client/lib/ui/feature/analysis/analysis_screen.dart` - 所要時間タブの追加
   - `client/lib/ui/feature/home/edit_work_log_dialog.dart` - 所要時間編集機能の追加

5. **インフラ**
   - `infra/module/firestore/main.tf` - 新しいインデックスの追加

## 制約事項

### 1. データ整合性

- デフォルト所要時間の設定値の妥当性を保つ必要がある
- 家事ログの所要時間編集時の整合性を保つ必要がある

### 2. パフォーマンス

- 大量のログデータに対する分析処理の最適化
- リアルタイム更新の負荷軽減

### 3. ユーザビリティ

- デフォルト所要時間の設定手間を最小限に抑える
- プリセット選択と手動入力の両方を提供し、柔軟性を確保する
- 家事ログ編集時の所要時間変更を直感的に行える

### 4. データ精度

- 所要時間の精度は分単位とする
- 所要時間の入力値の妥当性を保つ（1 分以上、最大 1440 分まで）

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
