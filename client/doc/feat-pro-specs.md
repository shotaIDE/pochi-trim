# Pro 版機能仕様書

## 概要

「Pro 版」は、House Worker アプリケーションの買い切り型有料課金機能です。この機能により、ユーザーはより多くの家事を登録できるようになります。

## 機能要件

### 基本仕様

- アプリには「フリー版」と「Pro 版」の 2 つの利用形態が存在する
- フリー版はアプリをインストールした全ユーザーが利用できる基本機能
- Pro 版は買い切り型の有料アップグレードとして提供される

### フリー版の制限

- フリー版では、家事（HouseWork）の登録数が最大 10 件までに制限される
- 制限に達した場合、新しい家事を登録しようとすると、Pro 版へのアップグレードを促すメッセージが表示される
- 既に 10 件登録されている状態でも、家事ログ（WorkLog）の登録は制限なく行える

### Pro 版の特典

- Pro 版では、家事（HouseWork）の登録数が無制限となる
- Pro 版は買い切り型の課金形式とし、一度購入すれば永続的に利用可能

## 技術要件

### データモデル

- アプリケーションの状態管理のために`AppSession.signedIn`モデルに`isPremium`フラグを追加する
- Pro 版購入時に、このフラグを`true`に更新する

```dart
// AppSession モデルの変更部分（追加予定）
@freezed
sealed class AppSession with _$AppSession {
  const AppSession._();

  factory AppSession.signedIn({
    required String userId,
    required String currentHouseId,
    @Default(false) bool isPremium, // Pro版フラグを追加
  }) = AppSessionSignedIn;
  factory AppSession.notSignedIn() = AppSessionNotSignedIn;
  factory AppSession.loading() = AppSessionLoading;
}
```

### 家事登録の制限ロジック

- 家事を新規登録する際、以下のチェックを行う：
  1. ユーザーが Pro 版かどうかを確認
  2. Pro 版でない場合、現在の家事登録数をカウント
  3. 登録数が 10 件以上の場合、エラーメッセージを表示し Pro 版へのアップグレードを促す

```dart
// 疑似コード - プレゼンターでの実装例
@riverpod
class AddHouseWorkPresenter extends _$AddHouseWorkPresenter {
  @override
  FutureOr<void> build() {
    // 初期化処理
  }

  Future<void> saveHouseWork(HouseWork houseWork) async {
    // セッションからPro版かどうかを確認
    final appSession = ref.read(rootAppInitializedProvider);
    final isPremium = switch (appSession) {
      AppSessionSignedIn(:final isPremium) => isPremium,
      _ => false,
    };

    if (!isPremium) {
      // Pro版でない場合、家事の数を確認
      final houseWorks = await ref.read(houseWorkRepositoryProvider).getAllOnce();
      if (houseWorks.length >= 10) {
        throw MaxHouseWorkLimitExceededException();
      }
    }

    // 家事を保存
    await ref.read(houseWorkRepositoryProvider).save(houseWork);
  }
}
```

### 課金処理

- 課金処理には、RevenueCat のライブラリ`purchases_flutter`を使用する
- 課金処理が完了したら、アプリケーションの`AppSession`の`isPremium`フラグを更新する

```dart
// 疑似コード - 課金サービスの実装例
class PurchaseService {
  final Ref _ref;

  PurchaseService(this._ref);

  Future<bool> purchasePro() async {
    try {
      // RevenueCatを使用して課金処理を実行
      final purchaseResult = await Purchases.purchaseProduct('pro_version');

      if (purchaseResult.customerInfo.entitlements.active.containsKey('pro_access')) {
        // 課金成功時の処理

        // アプリケーションのセッション状態を更新
        final appSession = _ref.read(rootAppInitializedProvider);
        if (appSession is AppSessionSignedIn) {
          _ref.read(rootPresenterProvider.notifier).updateSession(
            appSession.copyWith(isPremium: true),
          );
        }

        return true;
      }
    } catch (e) {
      // エラーハンドリング
      throw PurchaseException('Pro版の購入に失敗しました: $e');
    }

    return false;
  }
}
```

### UI 要素

#### Pro 版アップグレード画面

- Pro 版の特典と価格を明示
- 購入ボタンを配置
- 利用規約とプライバシーポリシーへのリンクを表示

#### 設定画面

- 現在の利用状態（フリー版/Pro 版）を表示
- フリー版ユーザーには Pro 版へのアップグレード動線を表示

#### 家事登録画面

- フリー版ユーザーが制限に達した場合、エラーメッセージと Pro 版へのアップグレード動線を表示

## 実装計画

1. セッションモデルの`isPremium`フラグを追加する実装を行う
2. 家事登録時の制限チェックロジックを実装
3. 課金処理のためのサービスクラスを実装
4. Pro 版アップグレード画面の UI 実装
5. 設定画面に Pro 版の状態表示を追加
6. 家事登録画面にエラーハンドリングと Pro 版への誘導を追加

## エラーハンドリング

### MaxHouseWorkLimitExceededException

フリー版ユーザーが家事登録制限（10 件）に達した場合に発生する例外。

```dart
class MaxHouseWorkLimitExceededException implements Exception {
  final String message = 'フリー版では最大10件までの家事しか登録できません。Pro版にアップグレードすると、無制限に家事を登録できます。';

  @override
  String toString() => message;
}
```

### PurchaseException

課金処理中にエラーが発生した場合に投げられる例外。

```dart
class PurchaseException implements Exception {
  final String message;

  PurchaseException(this.message);

  @override
  String toString() => message;
}
```

## テスト計画

### 機能テスト

1. フリー版ユーザーの家事登録制限テスト

   - 9 件登録時：正常に登録できることを確認
   - 10 件登録時：正常に登録できることを確認
   - 11 件登録時：エラーが発生し、Pro 版へのアップグレードが促されることを確認

2. Pro 版ユーザーの家事登録テスト

   - 11 件以上の家事を問題なく登録できることを確認

3. 課金処理テスト

   - 課金成功時：ユーザーの`isPremium`フラグが正しく更新されることを確認
   - 課金キャンセル時：適切なエラーメッセージが表示されることを確認

4. UI 表示テスト
   - フリー版ユーザー：Pro 版へのアップグレード動線が適切に表示されることを確認
   - Pro 版ユーザー：Pro 版の状態が正しく表示されることを確認

### テストコード実装計画

#### モデルテスト

```dart
// AppSessionのテスト
void main() {
  group('AppSession Tests', () {
    test('AppSessionSignedIn should default isPremium to false', () {
      final session = AppSession.signedIn(
        userId: 'test-user',
        currentHouseId: 'test-house',
      );

      expect(session.isPremium, isFalse);
    });
  });
}
```

#### プレゼンターテスト

```dart
// AddHouseWorkPresenterのテスト
@GenerateMocks([HouseWorkRepository])
void main() {
  late MockHouseWorkRepository mockRepository;
  late ProviderContainer container;

  setUp(() {
    mockRepository = MockHouseWorkRepository();
    container = ProviderContainer(
      overrides: [
        houseWorkRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('AddHouseWorkPresenter Tests', () {
    test('フリー版ユーザーが0件の場合、家事を登録できる', () async {
      // ...
    });

    test('フリー版ユーザーが1件の場合、家事を登録できる', () async {
      // セットアップ
      when(mockRepository.getAllOnce()).thenAnswer((_) async => List.generate(9, (i) =>
        HouseWork(
          id: 'id-$i',
          title: 'Test $i',
          icon: '🏠',
          createdAt: DateTime.now(),
          createdBy: 'test-user',
          isRecurring: false,
        )
      ));

      when(mockRepository.save(any)).thenAnswer((_) async => 'new-id');

      // テスト対象のプレゼンターを取得
      final presenter = container.read(addHouseWorkPresenterProvider.notifier);

      // 実行
      final newHouseWork = HouseWork(
        id: '',
        title: 'New HouseWork',
        icon: '🧹',
        createdAt: DateTime.now(),
        createdBy: 'test-user',
        isRecurring: false,
      );

      // 例外が発生しないことを確認
      await expectLater(
        () => presenter.saveHouseWork(newHouseWork),
        returnsNormally,
      );

      // リポジトリのsaveメソッドが呼ばれたことを確認
      verify(mockRepository.save(any)).called(1);
    });

    test('フリー版ユーザーが9件の場合、家事を登録できる', () async {
      // ...
    });

    test('フリー版ユーザーが10件の場合、家事を登録できない', () async {
      // セットアップ
      when(mockRepository.getAllOnce()).thenAnswer((_) async => List.generate(10, (i) =>
        HouseWork(
          id: 'id-$i',
          title: 'Test $i',
          icon: '🏠',
          createdAt: DateTime.now(),
          createdBy: 'test-user',
          isRecurring: false,
        )
      ));

      // テスト対象のプレゼンターを取得
      final presenter = container.read(addHouseWorkPresenterProvider.notifier);

      // 実行と検証
      final newHouseWork = HouseWork(
        id: '',
        title: 'New HouseWork',
        icon: '🧹',
        createdAt: DateTime.now(),
        createdBy: 'test-user',
        isRecurring: false,
      );

      // MaxHouseWorkLimitExceededExceptionがスローされることを確認
      await expectLater(
        () => presenter.saveHouseWork(newHouseWork),
        throwsA(isA<MaxHouseWorkLimitExceededException>()),
      );

      // リポジトリのsaveメソッドが呼ばれないことを確認
      verifyNever(mockRepository.save(any));
    });

    test('フリー版ユーザーが11件の場合、家事を登録できない', () async {
      // ...
    });

    test('Pro版ユーザーは0件の場合、家事を登録できる', () async {
      // セットアップ - Pro版ユーザーのセッションをモック
      container = ProviderContainer(
        overrides: [
          houseWorkRepositoryProvider.overrideWithValue(mockRepository),
          rootAppInitializedProvider.overrideWithValue(
            AppSession.signedIn(
              userId: 'test-user',
              currentHouseId: 'test-house',
              isPremium: true, // Pro版ユーザー
            ),
          ),
        ],
      );

      // 10件以上の家事が既に存在する状況をセットアップ
      when(mockRepository.getAllOnce()).thenAnswer((_) async => List.generate(20, (i) =>
        HouseWork(
          id: 'id-$i',
          title: 'Test $i',
          icon: '🏠',
          createdAt: DateTime.now(),
          createdBy: 'test-user',
          isRecurring: false,
        )
      ));

      when(mockRepository.save(any)).thenAnswer((_) async => 'new-id');

      // テスト対象のプレゼンターを取得
      final presenter = container.read(addHouseWorkPresenterProvider.notifier);

      // 実行
      final newHouseWork = HouseWork(
        id: '',
        title: 'New HouseWork',
        icon: '🧹',
        createdAt: DateTime.now(),
        createdBy: 'test-user',
        isRecurring: false,
      );

      // 例外が発生しないことを確認
      await expectLater(
        () => presenter.saveHouseWork(newHouseWork),
        returnsNormally,
      );

      // getAllOnceが呼ばれないことを確認（Pro版ユーザーは制限チェックをスキップ）
      verifyNever(mockRepository.getAllOnce());

      // リポジトリのsaveメソッドが呼ばれたことを確認
      verify(mockRepository.save(any)).called(1);
    });

    test('Pro版ユーザーは1件の場合、家事を登録できる', () async {
      // ...
    });

    test('Pro版ユーザーは9件の場合、家事を登録できる', () async {
      // ...
    });

    test('Pro版ユーザーは10件の場合、家事を登録できる', () async {
      // ...
    });

    test('Pro版ユーザーは11件の場合、家事を登録できる', () async {
      // ...
    });
  });
}
```

#### UI テスト

```dart
// Pro版アップグレード画面のテスト
void main() {
  testWidgets('Pro版アップグレード画面が正しく表示される', (WidgetTester tester) async {
    // テスト用のProviderContainerを作成
    final container = ProviderContainer(
      overrides: [
        // 必要なプロバイダーのオーバーライド
      ],
    );

    // 画面をレンダリング
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: ProUpgradeScreen(),
        ),
      ),
    );

    // 画面の要素が正しく表示されていることを確認
    expect(find.text('Pro版にアップグレード'), findsOneWidget);
    expect(find.text('家事の登録件数が無制限に'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget); // 購入ボタン

    // 価格が表示されていることを確認
    expect(find.textContaining('¥'), findsOneWidget);

    // 利用規約とプライバシーポリシーへのリンクが表示されていることを確認
    expect(find.text('利用規約'), findsOneWidget);
    expect(find.text('プライバシーポリシー'), findsOneWidget);
  });

  testWidgets('家事登録制限エラー時にPro版へのアップグレード案内が表示される', (WidgetTester tester) async {
    // テスト用のProviderContainerを作成
    final mockPresenter = MockAddHouseWorkPresenter();
    when(mockPresenter.saveHouseWork(any))
      .thenThrow(MaxHouseWorkLimitExceededException());

    final container = ProviderContainer(
      overrides: [
        addHouseWorkPresenterProvider.overrideWith(
          (ref) => mockPresenter,
        ),
      ],
    );

    // 画面をレンダリング
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: AddHouseWorkScreen(),
        ),
      ),
    );

    // フォームに入力
    await tester.enterText(find.byType(TextField).first, 'テスト家事');

    // 保存ボタンをタップ
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    // エラーダイアログが表示されることを確認
    expect(find.text('フリー版では最大10件までの家事しか登録できません。Pro版にアップグレードすると、無制限に家事を登録できます。'), findsOneWidget);

    // Pro版へのアップグレードボタンが表示されることを確認
    expect(find.text('Pro版にアップグレード'), findsOneWidget);

    // キャンセルボタンが表示されることを確認
    expect(find.text('キャンセル'), findsOneWidget);
  });
}
```
