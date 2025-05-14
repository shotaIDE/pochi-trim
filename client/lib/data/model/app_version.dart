import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_version.freezed.dart';

@freezed
abstract class AppVersion with _$AppVersion {
  factory AppVersion({required String version, required int buildNumber}) =
      _AppVersion;
}
