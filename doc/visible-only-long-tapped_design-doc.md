# 凡例ロングタップによる単一項目表示機能の設計ドキュメント

## 概要

分析画面において、凡例をロングタップすることで、その項目のみが可視状態になる機能を実装する。これにより、ユーザーは特定の家事項目に焦点を当てて分析することができるようになる。

## 現状の実装

現在の分析画面では、以下の機能が実装されている：

1. 分析画面には「家事の頻度分析」「曜日ごとの頻度分析」「時間帯ごとの頻度分析」の 3 つのモードがある
2. 「曜日ごとの頻度分析」と「時間帯ごとの頻度分析」では、画面下部に凡例が表示されている
3. 凡例をタップすると、その項目の表示/非表示を切り替えることができる
4. 表示/非表示の状態は `HouseWorkVisibilities` クラスで管理されている
5. 凡例の表示状態に応じて、グラフの表示も更新される

## 実装計画

### 1. `HouseWorkVisibilities` クラスの拡張

`HouseWorkVisibilities` クラスに単一項目表示のための新しいメソッド `showOnlyOne` を追加する。

```dart
// client/lib/features/analysis/analysis_presenter.dart
class HouseWorkVisibilities extends _$HouseWorkVisibilities {
  @override
  Map<String, bool> build() {
    return {};
  }

  void toggle({required String houseWorkId}) {
    final newState = Map<String, bool>.from(state);
    newState[houseWorkId] = !(state[houseWorkId] ?? true);
    state = newState;
  }

  // 新しく追加するメソッド
  void showOnlyOne({required String houseWorkId}) {
    // 現在の状態をコピー
    final newState = Map<String, bool>.from(state);

    // すべての項目を非表示に設定
    for (final key in newState.keys) {
      newState[key] = false;
    }

    // 指定された項目のみを表示状態に設定
    newState[houseWorkId] = true;

    state = newState;
  }

  bool isVisible({required String houseWorkId}) {
    return state[houseWorkId] ?? true;
  }
}
```

### 2. `_Legends` ウィジェットの拡張

`_Legends` ウィジェットに `onLongPress` コールバックを追加し、ロングタップ時に `HouseWorkVisibilities` の `showOnlyOne` メソッドを呼び出す。

```dart
// client/lib/features/analysis/analysis_screen.dart
class _Legends extends StatelessWidget {
  const _Legends({
    required this.legends,
    required this.onTap,
    required this.onLongPress, // 新しく追加するコールバック
  });

  final List<HouseWorkLegends> legends;
  final void Function(String houseWorkId) onTap;
  final void Function(String houseWorkId) onLongPress; // 新しく追加するコールバック

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            // 説明文を更新
            '凡例: (タップで表示/非表示を切り替え、ロングタップでその項目のみ表示)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            children: legends.map((legend) {
              return InkWell(
                onTap: () => onTap(legend.houseWork.id),
                onLongPress: () => onLongPress(legend.houseWork.id), // ロングタップハンドラを追加
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
```

### 3. `_WeekdayAnalysisPanel` と `_TimeSlotAnalysisPanel` クラスの更新

`_WeekdayAnalysisPanel` と `_TimeSlotAnalysisPanel` クラスで `_Legends` ウィジェットを使用している箇所を更新し、`onLongPress` コールバックを追加する。

```dart
// client/lib/features/analysis/analysis_screen.dart の _WeekdayAnalysisPanel クラス内
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
```

```dart
// client/lib/features/analysis/analysis_screen.dart の _TimeSlotAnalysisPanel クラス内
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
```

## 状態遷移の定義

以下の状態遷移を実装する：

1. **通常状態**：初期状態。全ての項目が表示されているか、ユーザーが任意に表示/非表示を設定した状態
2. **単一表示状態**：ロングタップにより、特定の項目のみが表示されている状態

状態遷移の規則：

- 通常状態で項目をロングタップ → 単一表示状態に移行（ロングタップされた項目のみ表示）
- 単一表示状態で表示されている項目をタップ → 通常状態に戻る（全項目表示）
- 単一表示状態で非表示の項目をタップ → その項目も表示状態になる（通常状態に移行）
- 単一表示状態で別の項目をロングタップ → その項目のみの単一表示状態に切り替わる

これらの状態遷移は、`HouseWorkVisibilities` クラスの既存の `toggle` メソッドと新しく追加する `showOnlyOne` メソッドによって実現される。

## アクセシビリティ対応

凡例項目には適切なセマンティックラベルを設定し、スクリーンリーダー対応を行う。

```dart
// client/lib/features/analysis/analysis_screen.dart の _Legends クラス内
return InkWell(
  onTap: () => onTap(legend.houseWork.id),
  onLongPress: () => onLongPress(legend.houseWork.id),
  child: Semantics(
    label: '${legend.houseWork.title} ${legend.isVisible ? "表示中" : "非表示中"}',
    hint: 'タップで表示/非表示を切り替え、ロングタップでこの項目のみ表示',
    child: Opacity(
      // 以下省略
    ),
  ),
);
```

## テスト計画

### 1. 単体テスト

`HouseWorkVisibilities` クラスの `showOnlyOne` メソッドのテストを実装する。

```dart
// client/test/features/analysis/analysis_presenter_test.dart
void main() {
  group('HouseWorkVisibilities', () {
    test('showOnlyOne should make only the specified item visible', () {
      // テスト用のProviderContainerを作成
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // 初期状態を確認
      expect(container.read(houseWorkVisibilitiesProvider), isEmpty);

      // いくつかの項目の表示状態を設定
      container.read(houseWorkVisibilitiesProvider.notifier).toggle(houseWorkId: 'item1');
      container.read(houseWorkVisibilitiesProvider.notifier).toggle(houseWorkId: 'item2');

      // item1を非表示、item2を表示に設定
      expect(container.read(houseWorkVisibilitiesProvider)['item1'], false);
      expect(container.read(houseWorkVisibilitiesProvider)['item2'], true);

      // showOnlyOneを呼び出し
      container.read(houseWorkVisibilitiesProvider.notifier).showOnlyOne(houseWorkId: 'item1');

      // item1のみが表示され、他は非表示になることを確認
      expect(container.read(houseWorkVisibilitiesProvider)['item1'], true);
      expect(container.read(houseWorkVisibilitiesProvider)['item2'], false);
    });
  });
}
```

### 2. ウィジェットテスト

`_Legends` ウィジェットのロングタップ機能をテストする。

```dart
// client/test/features/analysis/legends_widget_test.dart
void main() {
  testWidgets('_Legends widget should handle long press', (WidgetTester tester) async {
    // テスト用の変数
    String? tappedId;
    String? longPressedId;

    // テスト用のデータ
    final legends = [
      HouseWorkLegends(
        houseWork: HouseWork(id: 'item1', title: 'Item 1', icon: '🧹'),
        color: Colors.blue,
        isVisible: true,
      ),
      HouseWorkLegends(
        houseWork: HouseWork(id: 'item2', title: 'Item 2', icon: '🧽'),
        color: Colors.green,
        isVisible: true,
      ),
    ];

    // ウィジェットをビルド
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: _Legends(
            legends: legends,
            onTap: (id) => tappedId = id,
            onLongPress: (id) => longPressedId = id,
          ),
        ),
      ),
    );

    // 最初の項目をロングタップ
    await tester.longPress(find.text('Item 1'));
    await tester.pump();

    // onLongPressが正しく呼び出されたことを確認
    expect(longPressedId, 'item1');
    expect(tappedId, null);

    // 2番目の項目をタップ
    await tester.tap(find.text('Item 2'));
    await tester.pump();

    // onTapが正しく呼び出されたことを確認
    expect(tappedId, 'item2');
  });
}
```

### 3. 統合テスト

分析画面全体での機能をテストする。

```dart
// client/integration_test/analysis_screen_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Long press on legend should show only that item', (WidgetTester tester) async {
    // アプリを起動
    await tester.pumpWidget(const MyApp());

    // 分析画面に移動
    await tester.tap(find.byIcon(Icons.analytics));
    await tester.pumpAndSettle();

    // 曜日による分析を選択
    await tester.tap(find.text('曜日による分析'));
    await tester.pumpAndSettle();

    // 凡例の最初の項目を見つける
    final firstLegendItem = find.byType(InkWell).first;

    // ロングタップ
    await tester.longPress(firstLegendItem);
    await tester.pumpAndSettle();

    // グラフが更新されたことを確認（詳細な検証は実装に依存）
    // ...
  });
}
```

## 影響範囲

この機能実装により、以下のファイルに変更が必要になる：

1. `client/lib/features/analysis/analysis_presenter.dart`

   - `HouseWorkVisibilities` クラスに `showOnlyOne` メソッドを追加

2. `client/lib/features/analysis/analysis_screen.dart`

   - `_Legends` クラスに `onLongPress` パラメータを追加
   - `_WeekdayAnalysisPanel` と `_TimeSlotAnalysisPanel` クラスで `_Legends` ウィジェットの使用箇所を更新
   - 凡例の説明文を更新

3. テストファイル
   - 単体テスト、ウィジェットテスト、統合テストを追加

## パフォーマンスと応答性

- ロングタップ後の状態変更とグラフの更新は、既存の Riverpod の仕組みを活用して実装するため、パフォーマンスへの影響は最小限に抑えられる
- グラフの更新処理は既存の仕組みを活用し、パフォーマンスへの影響を最小限に抑える

## 将来の拡張性

1. **複数モード対応**

   - 現在は「曜日ごとの頻度分析」と「時間帯ごとの頻度分析」に凡例があるが、将来的に他の分析モードが追加された場合にも対応できる設計にする
   - `_Legends` ウィジェットは再利用可能なコンポーネントとして実装されているため、新しい分析モードでも同様に使用できる

2. **設定の永続化**

   - 将来的に、ユーザーが設定した表示/非表示状態を保存し、アプリ再起動後も維持する機能を追加する場合は、`HouseWorkVisibilities` クラスを拡張して永続化の仕組みを追加する

3. **複数項目の選択**
   - 将来的に、複数の特定項目だけを表示する機能を追加する場合は、`HouseWorkVisibilities` クラスに新しいメソッド（例: `showOnly(List<String> houseWorkIds)`）を追加する

## まとめ

凡例ロングタップによる単一項目表示機能は、ユーザーが特定の家事項目に焦点を当てて分析できるようにするための機能である。この機能は、既存の `HouseWorkVisibilities` クラスを拡張し、`_Legends` ウィジェットに `onLongPress` コールバックを追加することで実現する。また、凡例の説明文を更新し、アクセシビリティにも配慮する。テストコードも実装し、機能の正常動作を確認する。
