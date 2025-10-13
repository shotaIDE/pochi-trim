import 'package:package_info_plus/package_info_plus.dart';
import 'package:pochi_trim/data/model/app_version.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_info_service.g.dart';

@riverpod
Future<AppVersion> currentAppVersion(Ref ref) async {
  final packageInfo = await PackageInfo.fromPlatform();

  return AppVersion(
    version: packageInfo.version,
    buildNumber: int.parse(packageInfo.buildNumber),
  );
}
