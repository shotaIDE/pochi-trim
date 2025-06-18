import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_session.freezed.dart';

/// アプリ全体のセッション状態を表すクラス
///
/// この内容が変化した場合、アプリの再スタートが必要になるような、根管部分に関わるデータが含まれる。
@freezed
sealed class AppSession with _$AppSession {
  const AppSession._();

  factory AppSession.signedIn({required String currentHouseId}) =
      AppSessionSignedIn;

  factory AppSession.notSignedIn() = AppSessionNotSignedIn;
}
