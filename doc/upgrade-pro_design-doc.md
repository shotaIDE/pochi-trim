# upgrade_to_pro_screen RevenueCat 商品情報対応 デザイン Doc

## 概要

現在の `upgrade_to_pro_screen` で固定価格（¥980）が表示されている問題を解決し、RevenueCat から取得した商品情報を元に動的に購入画面を構築する機能を実装する。

## 現状分析

### 既存実装の確認結果

- **RevenueCat 設定**: `purchases_flutter: 8.8.1`, `purchases_ui_flutter: 8.8.1` が導入済み
- **初期化処理**: `main.dart` で RevenueCat の初期化が実装済み
- **エンタイトルメント管理**: `in_app_purchase_service.dart` で Pro ユーザー判定が実装済み
- **購入処理**: `purchase_pro_result.dart` で基本的な購入フローの骨格が存在
- **UI**: `upgrade_to_pro_screen.dart` で基本的な UI 構造が実装済み
- **AppSession**: Pro フラグ管理が実装済み

### 課題

- 価格表示が固定値（¥980）でハードコーディング
- RevenueCat の商品情報取得が未実装
- 購入処理で `RevenueCatUI.presentPaywall()` を使用しているが、商品情報との連携なし
- エラーハンドリングが不十分

## 実装計画

### Phase 1: データモデルとサービス層の実装

#### 1.1 商品情報モデルの定義

**ファイル**: `client/lib/data/model/pro_product_info.dart`

```dart
@freezed
class ProProductInfo with _$ProProductInfo {
  const factory ProProductInfo({
    required String productId,
    required String title,
    required String description,
    required String price,
    required String currencyCode,
    required double priceAmount,
  }) = _ProProductInfo;
}
```

#### 1.2 RevenueCat サービスの実装

**ファイル**: `client/lib/data/service/revenue_cat_service.dart`

```dart
@riverpod
class RevenueCatService extends _$RevenueCatService {
  @override
  Future<ProProductInfo?> build() async {
    try {
      final offerings = await Purchases.getOfferings();
      final currentOffering = offerings.current;

      if (currentOffering == null) return null;

      final proPackage = currentOffering.getPackage('pro');
      if (proPackage == null) return null;

      return ProProductInfo(
        productId: proPackage.storeProduct.identifier,
        title: proPackage.storeProduct.title,
        description: proPackage.storeProduct.description,
        price: proPackage.storeProduct.priceString,
        currencyCode: proPackage.storeProduct.currencyCode,
        priceAmount: proPackage.storeProduct.price,
      );
    } catch (e) {
      // エラーログ出力
      return null;
    }
  }
}
```

#### 1.3 購入状態管理の実装

**ファイル**: `client/lib/ui/feature/pro/pro_purchase_presenter.dart`

```dart
@freezed
class PurchaseState with _$PurchaseState {
  const factory PurchaseState.loading() = PurchaseStateLoading;
  const factory PurchaseState.loaded(ProProductInfo productInfo) = PurchaseStateLoaded;
  const factory PurchaseState.purchasing() = PurchaseStatePurchasing;
  const factory PurchaseState.success() = PurchaseStateSuccess;
  const factory PurchaseState.error(String message) = PurchaseStateError;
}

@riverpod
class ProPurchasePresenter extends _$ProPurchasePresenter {
  @override
  PurchaseState build() {
    final productInfoAsync = ref.watch(revenueCatServiceProvider);

    return productInfoAsync.when(
      data: (productInfo) => productInfo != null
        ? PurchaseState.loaded(productInfo)
        : const PurchaseState.error('商品情報を取得できませんでした'),
      loading: () => const PurchaseState.loading(),
      error: (_, __) => const PurchaseState.error('商品情報の取得に失敗しました'),
    );
  }

  Future<void> purchasePro() async {
    final currentState = state;
    if (currentState is! PurchaseStateLoaded) return;

    state = const PurchaseState.purchasing();

    try {
      final offerings = await Purchases.getOfferings();
      final proPackage = offerings.current?.getPackage('pro');

      if (proPackage == null) {
        state = const PurchaseState.error('商品が見つかりませんでした');
        return;
      }

      final customerInfo = await Purchases.purchasePackage(proPackage);

      if (customerInfo.entitlements.active[revenueCatProEntitlementId] != null) {
        // AppSession更新
        final appSession = ref.read(unwrappedCurrentAppSessionProvider);
        if (appSession is AppSessionSignedIn) {
          await ref.read(currentAppSessionProvider.notifier).upgradeToPro();
        }

        state = const PurchaseState.success();
      } else {
        state = const PurchaseState.error('購入処理が完了しませんでした');
      }
    } catch (e) {
      state = PurchaseState.error(_getErrorMessage(e));
    }
  }

  String _getErrorMessage(dynamic error) {
    // PurchasesErrorCode に応じた適切なエラーメッセージを返す
    return '購入処理中にエラーが発生しました';
  }
}
```

### Phase 2: UI 層の実装

#### 2.1 動的価格表示コンポーネント

**ファイル**: `client/lib/ui/feature/pro/upgrade_to_pro_screen.dart` (修正)

```dart
class _PriceDisplay extends ConsumerWidget {
  const _PriceDisplay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchaseState = ref.watch(proPurchasePresenterProvider);

    return purchaseState.when(
      loading: () => const _PriceLoadingSkeleton(),
      loaded: (productInfo) => _PriceContent(productInfo: productInfo),
      purchasing: () => _PriceContent(productInfo: productInfo),
      success: () => const _PriceContent(productInfo: productInfo),
      error: (message) => _PriceError(message: message),
    );
  }
}

class _PriceContent extends StatelessWidget {
  const _PriceContent({required this.productInfo});

  final ProProductInfo productInfo;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          productInfo.price,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          '一度購入すれば永続的に利用可能',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }
}

class _PriceLoadingSkeleton extends StatelessWidget {
  const _PriceLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: Column(
        children: [
          Container(
            width: 120,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 200,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}
```

#### 2.2 購入ボタンの改修

```dart
class _PurchaseButton extends ConsumerWidget {
  const _PurchaseButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchaseState = ref.watch(proPurchasePresenterProvider);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _getOnPressed(purchaseState, ref, context),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
        ),
        child: _getButtonChild(purchaseState),
      ),
    );
  }

  VoidCallback? _getOnPressed(PurchaseState state, WidgetRef ref, BuildContext context) {
    return state.maybeWhen(
      loaded: (_) => () => _handlePurchase(ref, context),
      error: (_) => () => _handleRetry(ref),
      orElse: () => null,
    );
  }

  Widget _getButtonChild(PurchaseState state) {
    return state.when(
      loading: () => const Text('読み込み中...'),
      loaded: (_) => const Text('Pro版を購入する'),
      purchasing: () => const SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      ),
      success: () => const Text('購入完了'),
      error: (_) => const Text('再試行'),
    );
  }

  Future<void> _handlePurchase(WidgetRef ref, BuildContext context) async {
    await ref.read(proPurchasePresenterProvider.notifier).purchasePro();

    final state = ref.read(proPurchasePresenterProvider);
    if (state is PurchaseStateSuccess && context.mounted) {
      Navigator.of(context).pop();
    }
  }

  void _handleRetry(WidgetRef ref) {
    ref.invalidate(revenueCatServiceProvider);
  }
}
```

### Phase 3: エラーハンドリングの強化

#### 3.1 エラー状態表示コンポーネント

```dart
class _ErrorDisplay extends StatelessWidget {
  const _ErrorDisplay({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.error_outline,
          size: 48,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(height: 16),
        Text(
          message,
          style: TextStyle(
            color: Theme.of(context).colorScheme.error,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: onRetry,
          child: const Text('再試行'),
        ),
      ],
    );
  }
}
```

#### 3.2 購入処理のエラーハンドリング強化

```dart
String _getErrorMessage(dynamic error) {
  if (error is PurchasesError) {
    switch (error.code) {
      case PurchasesErrorCode.purchaseCancelledError:
        return '購入がキャンセルされました';
      case PurchasesErrorCode.storeProblemError:
        return 'ストアに問題が発生しています。しばらく時間をおいて再試行してください';
      case PurchasesErrorCode.purchaseNotAllowedError:
        return '購入が許可されていません';
      case PurchasesErrorCode.purchaseInvalidError:
        return '無効な購入です';
      case PurchasesErrorCode.productNotAvailableForPurchaseError:
        return '商品が購入できません';
      case PurchasesErrorCode.networkError:
        return 'ネットワークエラーが発生しました。接続を確認してください';
      default:
        return '購入処理中にエラーが発生しました';
    }
  }
  return '予期しないエラーが発生しました';
}
```

### Phase 4: 既存ファイルの修正

#### 4.1 purchase_pro_result.dart の更新

```dart
@riverpod
class PurchaseProResult extends _$PurchaseProResult {
  @override
  Future<bool?> build() async {
    return null;
  }

  @Deprecated('Use ProPurchasePresenter instead')
  Future<bool> purchasePro() async {
    // 後方互換性のため残すが、新しい実装を使用することを推奨
    final presenter = ref.read(proPurchasePresenterProvider.notifier);
    await presenter.purchasePro();

    final state = ref.read(proPurchasePresenterProvider);
    return state is PurchaseStateSuccess;
  }
}
```

## テスト実装計画

### 1. 単体テスト

#### 1.1 RevenueCatService のテスト

**ファイル**: `client/test/data/service/revenue_cat_service_test.dart`

```dart
void main() {
  group('RevenueCatService', () {
    test('商品情報が正常に取得できること', () async {
      // Mock設定
      // テスト実行
      // 結果検証
    });

    test('商品が見つからない場合にnullを返すこと', () async {
      // テスト実装
    });

    test('エラーが発生した場合にnullを返すこと', () async {
      // テスト実装
    });
  });
}
```

#### 1.2 ProPurchasePresenter のテスト

**ファイル**: `client/test/ui/feature/pro/pro_purchase_presenter_test.dart`

```dart
void main() {
  group('ProPurchasePresenter', () {
    test('初期状態で商品情報を読み込むこと', () {
      // テスト実装
    });

    test('購入処理が正常に完了すること', () async {
      // テスト実装
    });

    test('購入エラー時に適切なエラー状態になること', () async {
      // テスト実装
    });
  });
}
```

### 2. ウィジェットテスト

#### 2.1 価格表示のテスト

**ファイル**: `client/test/ui/feature/pro/upgrade_to_pro_screen_test.dart`

```dart
void main() {
  group('UpgradeToProScreen', () {
    testWidgets('商品情報が正常に表示されること', (tester) async {
      // テスト実装
    });

    testWidgets('ローディング状態が正常に表示されること', (tester) async {
      // テスト実装
    });

    testWidgets('エラー状態が正常に表示されること', (tester) async {
      // テスト実装
    });
  });
}
```

### 3. 統合テスト

#### 3.1 購入フロー全体のテスト

**ファイル**: `client/test/integration/purchase_flow_test.dart`

```dart
void main() {
  group('購入フロー統合テスト', () {
    testWidgets('商品情報取得から購入完了までの一連の流れ', (tester) async {
      // 統合テスト実装
    });
  });
}
```

## 実装順序

### Step 1: データ層の実装

1. `ProProductInfo` モデルの作成
2. `RevenueCatService` の実装
3. 単体テストの作成

### Step 2: プレゼンテーション層の実装

1. `ProPurchasePresenter` の実装
2. 購入状態管理の実装
3. プレゼンター層のテスト作成

### Step 3: UI 層の実装

1. 動的価格表示コンポーネントの実装
2. 購入ボタンの改修
3. エラー表示コンポーネントの実装
4. ウィジェットテストの作成

### Step 4: エラーハンドリングの強化

1. 包括的なエラーハンドリングの実装
2. ユーザーフレンドリーなエラーメッセージの実装
3. リトライ機能の実装

### Step 5: 統合テストと最適化

1. 統合テストの実装
2. パフォーマンス最適化
3. 既存コードとの互換性確認

## 関連ファイル

### 新規作成ファイル

- `client/lib/data/model/pro_product_info.dart`
- `client/lib/data/service/revenue_cat_service.dart`
- `client/lib/ui/feature/pro/pro_purchase_presenter.dart`
- `client/test/data/service/revenue_cat_service_test.dart`
- `client/test/ui/feature/pro/pro_purchase_presenter_test.dart`
- `client/test/ui/feature/pro/upgrade_to_pro_screen_test.dart`
- `client/test/integration/purchase_flow_test.dart`

### 修正対象ファイル

- `client/lib/ui/feature/pro/upgrade_to_pro_screen.dart`
- `client/lib/data/service/purchase_pro_result.dart`

### 参照ファイル

- `client/lib/data/definition/app_definition.dart`
- `client/lib/data/service/in_app_purchase_service.dart`
- `client/lib/data/model/app_session.dart`
- `client/revenue-cat-config.json`

## 技術的考慮事項

### 1. パフォーマンス

- 商品情報のキャッシュ機能
- 不要な再取得の防止
- ローディング状態の最適化

### 2. セキュリティ

- RevenueCat API キーの適切な管理
- 購入検証の実装
- エンタイトルメント確認の強化

### 3. ユーザビリティ

- 直感的なエラーメッセージ
- 適切なローディング表示
- スムーズな購入フロー

### 4. 保守性

- 既存コードとの互換性維持
- テストカバレッジの確保
- コードの可読性向上

## 成功指標

- [ ] RevenueCat から商品情報が正常に取得される
- [ ] 動的価格表示が正常に機能する
- [ ] 購入処理が正常に完了する
- [ ] エラー状態が適切に処理される
- [ ] ローディング状態が適切に表示される
- [ ] 既存機能との互換性が保たれる
- [ ] テストカバレッジが 80%以上
- [ ] ユーザビリティが向上する
