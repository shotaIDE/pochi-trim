import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/services/auth_service.dart';

/// 現在のハウスIDを提供するプロバイダー
/// アプリケーション全体で一貫したハウスIDを使用するために使用します
final currentHouseIdProvider = Provider<String>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.currentUser?.uid ?? '';
});
