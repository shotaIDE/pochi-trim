import 'package:freezed_annotation/freezed_annotation.dart';

part 'emoji_category.freezed.dart';

@freezed
abstract class EmojiCategory with _$EmojiCategory {
  const factory EmojiCategory({
    required String name,
    required List<String> emojis,
  }) = _EmojiCategory;
}
