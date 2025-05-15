# 家事一覧タブ設計ドキュメント

## 1. 概要

家事一覧タブは、ユーザーが登録した全ての家事を一覧表示し、家事の登録・完了・詳細確認・削除などの操作を行うための画面です。ホーム画面のタブの一つとして実装されます。このタブは、ユーザーが登録した家事を効率的に管理し、家事の完了を記録するための中心的な機能を提供します。

## 2. 機能要件

### 2.1 表示要件

1. **家事一覧の表示**

   - 登録されている全ての家事を、登録日時が新しい順（降順）に表示する
   - 各家事アイテムには以下の情報を表示する
     - 家事の名前
     - 家事のアイコン（絵文字）

2. **空の状態の表示**

   - 登録されている家事がない場合は、適切なメッセージとアイコンを表示する
   - 例: 「登録されている家事はありません」というメッセージと、関連するアイコンを表示

3. **読み込み中の表示**

   - データ取得中はスケルトンアイテムを 10 件表示する
   - スケルトンアイテムの作り方は、home_screen.dart の`_QuickRegisterBottomBarState`における`Skeletonizer`を参考にする

4. **エラー状態の表示**
   - データ取得に失敗した場合は、エラーメッセージを表示する

### 2.2 操作要件

1. **家事の完了登録**

   - 家事アイテムの左側がタップされた際、その家事の家事ログを現在時刻で登録する
   - 登録成功時は以下のような適切なフィードバックを表示する
     - スナックバーでの通知
     - 家事ログのタブをハイライトする

2. **家事詳細の表示**

   - 家事アイテムの右側がタップされた際、その家事の家事ダッシュボードに遷移する
   - 家事ダッシュボードでは、家事の詳細情報や完了履歴を確認できる

3. **家事の削除**

   - 家事アイテムが左スワイプされた際、確認ダイアログを表示する
   - 確認後、家事を削除する
   - 削除成功時は適切なフィードバック（例: スナックバーでの通知）を表示する

4. **一覧の更新**
   - プルダウンで一覧を更新できる（プルトゥリフレッシュ）

### 2.3 制約条件

1. **家事数の制限**

   - 無料ユーザーは最大 10 件までの家事しか登録できない
   - 制限に達した場合、Pro 版へのアップグレードを促すダイアログを表示する

2. **パフォーマンス**
   - 大量の家事がある場合でも、スムーズにスクロールできるようにする
   - データの取得と表示を最適化する

## 3. 技術要件

### 3.1 データモデル

1. **家事モデル（HouseWork）**

   - 既存のモデルを使用する
   - 主要フィールド:
     - id: 家事の ID（文字列）
     - title: 家事の名前（文字列）
     - icon: 家事のアイコン（絵文字、文字列）
     - createdAt: 家事の作成日時（DateTime）
     - createdBy: 家事の作成者 ID（文字列）
     - isRecurring: 定期的な家事かどうか（真偽値）
     - recurringIntervalMs: 定期的な家事の場合の間隔（ミリ秒、整数、オプション）

2. **家事ログモデル（WorkLog）**
   - 既存のモデルを使用する
   - 主要フィールド:
     - id: 家事ログの ID（文字列）
     - houseWorkId: 関連する家事の ID（文字列）
     - completedAt: 完了時刻（DateTime）
     - completedBy: 実行したユーザーの ID（文字列）

### 3.2 リポジトリ

1. **家事リポジトリ（HouseWorkRepository）**

   - 既存のリポジトリを修正する
   - `getAll()`メソッドを修正し、`createdBy`ではなく`createdAt`でソートするようにする
   - ソート順は降順（descending: true）とする

2. **家事ログリポジトリ（WorkLogRepository）**
   - 既存のリポジトリを使用する
   - 家事ログの登録、取得、削除などの機能を提供する

### 3.3 プレゼンター

1. **家事一覧プレゼンター（HouseWorkListPresenter）**
   - 新規作成する
   - 家事一覧の取得、家事の削除、家事ログの登録などの機能を提供する
   - Riverpod を使用して状態管理を行う

### 3.4 UI コンポーネント

1. **家事一覧タブ（HouseWorkListTab）**

   - 新規作成する
   - 家事一覧の表示、家事の操作などの機能を提供する
   - 既存のホーム画面のタブとして組み込む

2. **家事アイテム（HouseWorkItem）**
   - 新規作成する
   - 家事の情報を表示し、タップやスワイプなどの操作を処理する
   - 左側と右側で異なる動作をするため、適切にタップ領域を分割する

## 4. 実装計画

### 4.1 リポジトリの修正

1. **HouseWorkRepository の修正**
   - `getAll()`メソッドを修正し、`createdBy`ではなく`createdAt`でソートするようにする
   - ソート順は降順（descending: true）とする

```dart
// 修正前
Stream<List<HouseWork>> getAll() {
  return _getHouseWorksCollection()
      .orderBy('createdBy', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(HouseWork.fromFirestore).toList());
}

// 修正後
Stream<List<HouseWork>> getAll() {
  return _getHouseWorksCollection()
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(HouseWork.fromFirestore).toList());
}
```

### 4.2 プレゼンターの実装

1. **HouseWorkListPresenter の実装**
   - 家事一覧の取得、家事の削除、家事ログの登録などの機能を提供する
   - Riverpod を使用して状態管理を行う

```dart
// client/lib/features/home/house_work_list_presenter.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pochi_trim/models/house_work.dart';
import 'package:pochi_trim/repositories/house_work_repository.dart';
import 'package:pochi_trim/services/work_log_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'house_work_list_presenter.g.dart';

@riverpod
Stream<List<HouseWork>> houseWorks(Ref ref) {
  final houseWorkRepository = ref.watch(houseWorkRepositoryProvider);
  return houseWorkRepository.getAll();
}

@riverpod
Future<bool> deleteHouseWork(Ref ref, String houseWorkId) async {
  final houseWorkRepository = ref.read(houseWorkRepositoryProvider);
  return houseWorkRepository.delete(houseWorkId);
}
```

### 4.3 UI コンポーネントの実装

1. **HouseWorkListTab の実装**
   - 家事一覧の表示、家事の操作などの機能を提供する
   - 既存のホーム画面のタブとして組み込む

```dart
// client/lib/features/home/house_work_list_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pochi_trim/features/home/house_work_item.dart';
import 'package:pochi_trim/features/home/house_work_list_presenter.dart';
import 'package:pochi_trim/features/home/work_log_dashboard_screen.dart';
import 'package:pochi_trim/models/house_work.dart';
import 'package:pochi_trim/models/work_log.dart';
import 'package:skeletonizer/skeletonizer.dart';

class HouseWorkListTab extends ConsumerWidget {
  const HouseWorkListTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final houseWorksAsync = ref.watch(houseWorksProvider);

    return houseWorksAsync.when(
      data: (houseWorks) {
        if (houseWorks.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.home_work, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  '登録されている家事はありません',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  '家事を追加すると、ここに表示されます',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            // プロバイダーを更新して最新のデータを取得
            ref.invalidate(houseWorksProvider);
          },
          child: ListView.builder(
            itemCount: houseWorks.length,
            itemBuilder: (context, index) {
              final houseWork = houseWorks[index];
              return HouseWorkItem(
                houseWork: houseWork,
                onLeftTap: () async {
                  // 家事ログを記録
                  final presenter = ref.read(houseWorkListPresenterProvider.notifier);
                  await presenter.recordWorkLog(context, houseWork.id);
                },
                onRightTap: () {
                  // 家事ダッシュボード画面に遷移
                  final workLog = WorkLog(
                    id: '',
                    houseWorkId: houseWork.id,
                    completedAt: DateTime.now(),
                    completedBy: '',
                  );
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => WorkLogDashboardScreen(workLog: workLog),
                    ),
                  );
                },
                onDelete: () async {
                  // 削除確認ダイアログを表示
                  final shouldDelete = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('家事の削除'),
                      content: const Text('この家事を削除してもよろしいですか？'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('キャンセル'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('削除'),
                        ),
                      ],
                    ),
                  );

                  if (shouldDelete == true) {
                    // 家事を削除
                    final presenter = ref.read(houseWorkListPresenterProvider.notifier);
                    final success = await presenter.deleteHouseWork(houseWork.id);

                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('家事を削除しました')),
                      );
                    }
                  }
                },
              );
            },
          ),
        );
      },
      loading: () => Skeletonizer(
        enabled: true,
        child: ListView.builder(
          itemCount: 10,
          itemBuilder: (context, index) => const _SkeletonHouseWorkItem(),
        ),
      ),
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'エラーが発生しました: $error',
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(houseWorksProvider),
              child: const Text('再試行'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonHouseWorkItem extends StatelessWidget {
  const _SkeletonHouseWorkItem();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 12),
              child: const Text('🏠', style: TextStyle(fontSize: 24)),
            ),
            const Expanded(
              child: Text(
                'サンプル家事',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
```

2. **HouseWorkItem の実装**
   - 家事の情報を表示し、タップやスワイプなどの操作を処理する
   - 左側と右側で異なる動作をするため、適切にタップ領域を分割する

```dart
// client/lib/features/home/house_work_item.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pochi_trim/models/house_work.dart';

class HouseWorkItem extends StatelessWidget {
  const HouseWorkItem({
    super.key,
    required this.houseWork,
    required this.onLeftTap,
    required this.onRightTap,
    required this.onDelete,
  });

  final HouseWork houseWork;
  final VoidCallback onLeftTap;
  final VoidCallback onRightTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('houseWork-${houseWork.id}'),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        // 削除処理は親ウィジェットに委譲
        onDelete();
        // Dismissibleのアニメーションを元に戻す
        return false;
      },
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            // 左側のタップ領域（家事ログを記録）
            Expanded(
              flex: 3,
              child: InkWell(
                onTap: () async {
                  await HapticFeedback.mediumImpact();
                  onLeftTap();
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // アイコンを表示
                      Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        width: 40,
                        height: 40,
                        margin: const EdgeInsets.only(right: 12),
                        child: Text(
                          houseWork.icon,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          houseWork.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // 右側のタップ領域（家事ダッシュボードに遷移）
            InkWell(
              onTap: onRightTap,
              child: Container(
                padding: const EdgeInsets.all(16),
                child: const Icon(Icons.chevron_right),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 4.4 ホーム画面への統合

1. **HomeScreen の修正**
   - これから行う予定家事一覧のタブを家事一覧タブに差し替える

```dart
// client/lib/features/home/home_screen.dart の修正部分
// ...
body: TabBarView(
  children: [
    // 家事一覧タブ
    const HouseWorkListTab(),
    // 完了した家事ログ一覧のタブ
    _CompletedWorkLogsTab(),
  ],
),
// ...

// TabBarの修正部分
bottom: TabBar(
  onTap: (index) {
    ref.read(selectedTabProvider.notifier).state = index;
  },
  tabs: const [
    Tab(icon: Icon(Icons.home_work), text: '家事一覧'),
    Tab(icon: Icon(Icons.task_alt), text: '完了家事'),
  ],
),
// ...
```

## 5. テスト計画

### 5.1 単体テスト

1. **HouseWorkRepository のテスト**
   - `getAll()`メソッドが`createdAt`でソートされていることを確認する
   - ソート順が降順であることを確認する

```dart
// client/test/repositories/house_work_repository_test.dart
void main() {
  group('HouseWorkRepository', () {
    test('getAll should sort by createdAt in descending order', () async {
      // モックの設定
      // テスト実行
      // 検証
    });
  });
}
```

2. **HouseWorkListPresenter のテスト**
   - `deleteHouseWork()`メソッドが正しく動作することを確認する
   - `recordWorkLog()`メソッドが正しく動作することを確認する

```dart
// client/test/features/home/house_work_list_presenter_test.dart
void main() {
  group('HouseWorkListPresenter', () {
    test('deleteHouseWork should delete a house work', () async {
      // モックの設定
      // テスト実行
      // 検証
    });

    test('recordWorkLog should record a work log', () async {
      // モックの設定
      // テスト実行
      // 検証
    });
  });
}
```

### 5.2 ウィジェットテスト

1. **HouseWorkListTab のテスト**
   - 家事一覧が正しく表示されることを確認する
   - 空の状態が正しく表示されることを確認する
   - 読み込み中の状態が正しく表示されることを確認する
   - エラー状態が正しく表示されることを確認する

```dart
// client/test/features/home/house_work_list_tab_test.dart
void main() {
  group('HouseWorkListTab', () {
    testWidgets('should display house works', (WidgetTester tester) async {
      // モックの設定
      // テスト実行
      // 検証
    });

    testWidgets('should display empty state', (WidgetTester tester) async {
      // モックの設定
      // テスト実行
      // 検証
    });

    testWidgets('should display loading state', (WidgetTester tester) async {
      // モックの設定
      // テスト実行
      // 検証
    });

    testWidgets('should display error state', (WidgetTester tester) async {
      // モックの設定
      // テスト実行
      // 検証
    });
  });
}
```

2. **HouseWorkItem のテスト**
   - 左側のタップが正しく動作することを確認する
   - 右側のタップが正しく動作することを確認する
   - スワイプが正しく動作することを確認する

```dart
// client/test/features/home/house_work_item_test.dart
void main() {
  group('HouseWorkItem', () {
    testWidgets('should handle left tap', (WidgetTester tester) async {
      // モックの設定
      // テスト実行
      // 検証
    });

    testWidgets('should handle right tap', (WidgetTester tester) async {
      // モックの設定
      // テスト実行
      // 検証
    });

    testWidgets('should handle swipe', (WidgetTester tester) async {
      // モックの設定
      // テスト実行
      // 検証
    });
  });
}
```

### 5.3 統合テスト

1. **家事一覧タブの統合テスト**
   - 家事一覧タブが正しく動作することを確認する
   - 家事の完了登録が正しく動作することを確認する
   - 家事の詳細表示が正しく動作することを確認する
   - 家事の削除が正しく動作することを確認する

```dart
// client/integration_test/house_work_list_tab_test.dart
void main() {
  group('HouseWorkListTab Integration', () {
    testWidgets('should display and interact with house works', (WidgetTester tester) async {
      // アプリの起動
      // テスト実行
      // 検証
    });
  });
}
```

## 6. 今後の拡張性

1. **家事の検索機能**

   - 家事名やアイコンで検索できる機能を追加する可能性がある

2. **家事のフィルタリング機能**

   - 特定の条件（例: 作成者、頻度など）で家事をフィルタリングする機能を追加する可能性がある

3. **家事の並び替え機能**
   - 作成日時以外の条件（例: 名前、完了回数など）で家事を並び替える機能を追加する可能性がある
