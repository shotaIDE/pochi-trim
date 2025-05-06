# 家事完了時のアニメーション実装計画

## 概要

本ドキュメントでは、家事完了時のアニメーション実装に関する設計と実装計画を詳細に記述します。要件定義に基づき、ユーザーが家事を完了した際の視覚的フィードバックを強化するための 2 つのアニメーション機能を実装します。

## 実装する機能

1. **完了アイコンのアニメーション**

   - 家事アイテムの完了ボタンをタップした時、アイコンが変化するアニメーション
   - フェードエフェクトを使用した自然な遷移

2. **ログ一覧タブのハイライト**
   - 家事完了時にログ一覧タブを一瞬ハイライトするアニメーション
   - フェードイン・フェードアウトのエフェクトを使用

## 技術的アプローチ

### 1. 完了アイコンのアニメーション

#### 現状分析

現在の実装では、`HouseWorkItem` クラス内で完了ボタンのアイコンが以下のように定義されています：

```dart
final doCompleteIcon = Icon(
  Icons.check_circle_outline,
  color: Theme.of(context).colorScheme.onSurface,
);
```

このアイコンは静的であり、タップ時に変化しません。

#### 実装計画

1. `HouseWorkItem` クラスを `StatefulWidget` に変更し、アニメーション状態を管理します。
2. `AnimatedSwitcher` を使用して、アイコン間の遷移をアニメーション化します。

```dart
// 疑似コード
class HouseWorkItem extends StatefulWidget {
  // 現在の実装と同じコンストラクタ

  @override
  State<HouseWorkItem> createState() => _HouseWorkItemState();
}

class _HouseWorkItemState extends State<HouseWorkItem> {
  bool _isCompleting = false;

  @override
  Widget build(BuildContext context) {
    // アイコンの定義を変更
    final doCompleteIcon = AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: _isCompleting
          ? Icon(
              Icons.check_circle,
              key: const ValueKey('check_circle'),
              color: Theme.of(context).colorScheme.primary,
            )
          : Icon(
              Icons.check_circle_outline,
              key: const ValueKey('check_circle_outline'),
              color: Theme.of(context).colorScheme.onSurface,
            ),
    );

    // completeButtonPart の onTap を修正
    final completeButtonPart = InkWell(
      onTap: () {
        setState(() {
          _isCompleting = true;
        });

        // アニメーション後に元に戻す
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() {
              _isCompleting = false;
            });
          }
        });

        // 元の処理を呼び出す
        widget.onCompleteTap(widget.houseWork);
      },
      // 残りは現在の実装と同じ
    );

    // 残りのビルドメソッドは現在の実装と同じ
  }
}
```

### 2. ログ一覧タブのハイライト

#### 現状分析

現在の実装では、`HomeScreen` クラスでタブが以下のように定義されています：

```dart
TabBar(
  onTap: (index) {
    ref.read(selectedTabProvider.notifier).state = index;
  },
  tabs: const [
    Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 8,
        children: [Icon(Icons.home), Text('家事')],
      ),
    ),
    Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 8,
        children: [Icon(Icons.check_circle), Text('ログ')],
      ),
    ),
  ],
),
```

このタブバーは静的であり、家事完了時にログタブをハイライトする機能はありません。

#### 実装計画

1. `HomeScreen` クラスを `StatefulWidget` に変更し、ログタブのハイライト状態を管理します。
2. `HouseWorksTab` クラスに家事完了時のコールバックを追加します。
3. `TabBar` をカスタマイズして、ハイライト状態に応じて表示を変更します。

```dart
// 疑似コード
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isLogTabHighlighted = false;

  void _onHouseWorkCompleted() {
    // 家事完了時にログタブをハイライト
    setState(() {
      _isLogTabHighlighted = true;
    });

    // 500ミリ秒後にハイライトを解除
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isLogTabHighlighted = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 選択されているタブを取得
    final selectedTab = ref.watch(selectedTabProvider);

    return DefaultTabController(
      length: 2,
      initialIndex: selectedTab,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('家事ログ'),
          actions: [
            // 現在の実装と同じ
          ],
          bottom: TabBar(
            onTap: (index) {
              ref.read(selectedTabProvider.notifier).state = index;
            },
            tabs: [
              const Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 8,
                  children: [Icon(Icons.home), Text('家事')],
                ),
              ),
              Tab(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isLogTabHighlighted
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 8,
                    children: [Icon(Icons.check_circle), Text('ログ')],
                  ),
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            HouseWorksTab(onHouseWorkCompleted: _onHouseWorkCompleted),
            const WorkLogsTab(),
          ],
        ),
        // 残りは現在の実装と同じ
      ),
    );
  }
}
```

### 3. HouseWorksTab の修正

#### 現状分析

現在、家事完了時の処理は `HouseWorksTab` クラスの `_onCompleteTapped` メソッドで行われています：

```dart
Future<void> _onCompleteTapped(HouseWork houseWork) async {
  final result = await ref.read(
    onCompleteHouseWorkTappedResultProvider(houseWork).future,
  );

  if (!mounted) {
    return;
  }

  if (!result) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('家事の記録に失敗しました。しばらくしてから再度お試しください')),
    );
    return;
  }

  ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('家事を記録しました')));
}
```

この処理は家事完了の成功/失敗を処理していますが、親コンポーネント（HomeScreen）に通知する機能はありません。

#### 実装計画

`HouseWorksTab` クラスに家事完了時のコールバックを追加します：

```dart
// 疑似コード
class HouseWorksTab extends ConsumerStatefulWidget {
  const HouseWorksTab({
    super.key,
    required this.onHouseWorkCompleted,
  });

  final VoidCallback onHouseWorkCompleted;

  @override
  ConsumerState<HouseWorksTab> createState() => _HouseWorksTabState();
}

class _HouseWorksTabState extends ConsumerState<HouseWorksTab> {
  // 現在の実装と同じ

  Future<void> _onCompleteTapped(HouseWork houseWork) async {
    final result = await ref.read(
      onCompleteHouseWorkTappedResultProvider(houseWork).future,
    );

    if (!mounted) {
      return;
    }

    if (!result) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('家事の記録に失敗しました。しばらくしてから再度お試しください')),
      );
      return;
    }

    // 家事完了を親コンポーネントに通知
    widget.onHouseWorkCompleted();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('家事を記録しました')));
  }

  // 残りは現在の実装と同じ
}
```

## テスト計画

### 単体テスト

1. **完了アイコンのアニメーションテスト**
   - `HouseWorkItem` ウィジェットのテスト
   - タップ時にアイコンが変化することを確認
   - 300 ミリ秒後にアイコンが元に戻ることを確認

```dart
// 疑似コード
testWidgets('完了アイコンのアニメーションテスト', (WidgetTester tester) async {
  // テスト用のHouseWorkを作成
  final houseWork = HouseWork(
    id: 'test-id',
    title: 'テスト家事',
    icon: '🧹',
    createdAt: DateTime.now(),
    createdBy: 'test-user',
    isRecurring: false,
  );

  bool onCompleteTapCalled = false;

  // HouseWorkItemをレンダリング
  await tester.pumpWidget(
    MaterialApp(
      home: HouseWorkItem(
        houseWork: houseWork,
        onCompleteTap: (_) {
          onCompleteTapCalled = true;
        },
        onMoveTap: (_) {},
        onDelete: (_) {},
      ),
    ),
  );

  // 初期状態では outline アイコンが表示されていることを確認
  expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
  expect(find.byIcon(Icons.check_circle), findsNothing);

  // 完了ボタンをタップ
  await tester.tap(find.byIcon(Icons.check_circle_outline));
  await tester.pump();

  // コールバックが呼ばれたことを確認
  expect(onCompleteTapCalled, true);

  // アイコンが変化したことを確認
  expect(find.byIcon(Icons.check_circle), findsOneWidget);
  expect(find.byIcon(Icons.check_circle_outline), findsNothing);

  // 300ミリ秒後
  await tester.pump(const Duration(milliseconds: 300));

  // アイコンが元に戻ったことを確認
  expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
  expect(find.byIcon(Icons.check_circle), findsNothing);
});
```

2. **ログタブのハイライトテスト**
   - `HomeScreen` ウィジェットのテスト
   - 家事完了イベント発生時にログタブがハイライトされることを確認
   - 500 ミリ秒後にハイライトが解除されることを確認

```dart
// 疑似コード
testWidgets('ログタブのハイライトテスト', (WidgetTester tester) async {
  // HomeScreenをレンダリング
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: HomeScreen(),
      ),
    ),
  );

  // 初期状態ではハイライトされていないことを確認
  final logTab = find.text('ログ').parent();
  final container = find.descendant(
    of: logTab,
    matching: find.byType(AnimatedContainer),
  );
  expect(
    tester.widget<AnimatedContainer>(container).decoration,
    isA<BoxDecoration>().having(
      (d) => d.color,
      'color',
      Colors.transparent,
    ),
  );

  // 家事完了イベントを発生させる
  final container = tester.element(find.byType(HomeScreen));
  final homeScreenState = container.state as _HomeScreenState;
  homeScreenState._onHouseWorkCompleted();
  await tester.pump();

  // ハイライトされていることを確認
  expect(
    tester.widget<AnimatedContainer>(container).decoration,
    isA<BoxDecoration>().having(
      (d) => d.color,
      'color',
      isNot(Colors.transparent),
    ),
  );

  // 500ミリ秒後
  await tester.pump(const Duration(milliseconds: 500));

  // ハイライトが解除されていることを確認
  expect(
    tester.widget<AnimatedContainer>(container).decoration,
    isA<BoxDecoration>().having(
      (d) => d.color,
      'color',
      Colors.transparent,
    ),
  );
});
```

### 統合テスト

1. **家事完了フローのテスト**
   - 家事アイテムをタップして完了処理を実行
   - アイコンのアニメーションが実行されることを確認
   - ログタブがハイライトされることを確認
   - スナックバーが表示されることを確認

```dart
// 疑似コード
testWidgets('家事完了フローのテスト', (WidgetTester tester) async {
  // アプリ全体をレンダリング
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        // モックプロバイダーの設定
      ],
      child: MaterialApp(
        home: HomeScreen(),
      ),
    ),
  );

  // 家事アイテムを見つけてタップ
  await tester.tap(find.byType(HouseWorkItem).first);
  await tester.pump();

  // アイコンのアニメーションを確認
  expect(find.byIcon(Icons.check_circle), findsOneWidget);

  // ログタブのハイライトを確認
  final logTab = find.text('ログ').parent();
  final container = find.descendant(
    of: logTab,
    matching: find.byType(AnimatedContainer),
  );
  expect(
    tester.widget<AnimatedContainer>(container).decoration,
    isA<BoxDecoration>().having(
      (d) => d.color,
      'color',
      isNot(Colors.transparent),
    ),
  );

  // スナックバーの表示を確認
  expect(find.text('家事を記録しました'), findsOneWidget);

  // アニメーション完了後の状態を確認
  await tester.pump(const Duration(milliseconds: 500));
  expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
  expect(
    tester.widget<AnimatedContainer>(container).decoration,
    isA<BoxDecoration>().having(
      (d) => d.color,
      'color',
      Colors.transparent,
    ),
  );
});
```

## 実装スケジュール

1. **準備フェーズ (1 日)**

   - 既存コードの詳細分析
   - 必要なクラスとメソッドの特定
   - テスト環境のセットアップ

2. **実装フェーズ (2 日)**

   - 完了アイコンのアニメーション実装 (0.5 日)
   - ログタブのハイライト実装 (1 日)
   - HouseWorksTab の修正とコールバック追加 (0.5 日)

3. **テストフェーズ (1 日)**

   - 単体テストの実装と実行
   - 統合テストの実装と実行
   - バグ修正

4. **リリースフェーズ (0.5 日)**
   - コードレビュー
   - ドキュメント更新
   - リリース準備

## リスクと対策

1. **パフォーマンスリスク**

   - **リスク**: アニメーションがデバイスのパフォーマンスに影響を与える可能性
   - **対策**: 軽量なアニメーションを使用し、必要に応じてパフォーマンステストを実施

2. **互換性リスク**

   - **リスク**: 古いデバイスや特定の OS バージョンでアニメーションが正しく動作しない可能性
   - **対策**: 複数のデバイスと OS バージョンでテストを実施

3. **アクセシビリティリスク**

   - **リスク**: アニメーションがアクセシビリティ設定と競合する可能性
   - **対策**: システムのアニメーション設定を尊重するコードを実装

4. **状態管理リスク**
   - **リスク**: アニメーション中に画面遷移や状態変更が発生した場合の問題
   - **対策**: `mounted` チェックを適切に実装し、非同期処理を安全に扱う

## まとめ

本ドキュメントでは、家事完了時のアニメーション実装に関する設計と実装計画を詳細に記述しました。2 つのアニメーション機能（完了アイコンのアニメーションとログ一覧タブのハイライト）を実装することで、ユーザーが家事を完了した際の視覚的フィードバックを強化します。

実装は既存のコードベースとの互換性を維持しながら、Flutter のアニメーション機能を活用して行います。また、適切なテストを実施することで、機能の正確性とパフォーマンスを確保します。
