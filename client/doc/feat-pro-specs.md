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

- `AppSession.signedIn`モデルに`isPremium`フラグが追加し、これを活用する
- Pro 版購入時に、ユーザーの`isPremium`フラグを`true`に更新する

```dart
// 関連部分
@freezed
sealed class AppSession with _$AppSession {
  const AppSession._();

  factory AppSession.signedIn({
    required String userId,
    required String currentHouseId,
    required bool isPremium, // Pro版フラグ
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
// 疑似コード
Future<String> saveHouseWork(HouseWork houseWork) async {
  final user = await userRepository.getUserByUid(currentUserId);

  if (!user.isPremium) {
    final houseWorks = await houseWorkRepository.getAllOnce();
    if (houseWorks.length >= 10) {
      throw MaxHouseWorkLimitExceededError();
    }
  }

  return houseWorkRepository.save(houseWork);
}
```

### 課金処理

- 課金処理には、RevenueCat のライブラリ purchases_flutter を使用する
- 課金処理が完了したら、Firestore 上のユーザードキュメントの`isPremium`フラグを更新する

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

### MaxHouseWorkLimitExceededError

フリー版ユーザーが家事登録制限（10 件）に達した場合に発生するエラー。

```dart
class MaxHouseWorkLimitExceededException implements Exception {
  final String message = 'フリー版では最大10件までの家事しか登録できません。Pro版にアップグレードすると、無制限に家事を登録できます。';

  @override
  String toString() => message;
}
```

## テスト計画

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
