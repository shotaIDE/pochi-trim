import 'package:flutter_riverpod/flutter_riverpod.dart';

// ハウスIDを提供するプロバイダー
final currentHouseIdProvider = Provider<String>((ref) {
  // TODO(ide): 適切な値に置き換える
  return 'default-house-id';
});
