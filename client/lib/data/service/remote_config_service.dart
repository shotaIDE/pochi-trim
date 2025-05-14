import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'remote_config_service.g.dart';

@riverpod
class UpdatedRemoteConfigKeys extends _$UpdatedRemoteConfigKeys {
  @override
  Stream<Set<String>> build() {
    return FirebaseRemoteConfig.instance.onConfigUpdated.map(
      (event) => event.updatedKeys,
    );
  }

  Future<void> ensureActivateFetchedRemoteConfigs() async {
    await FirebaseRemoteConfig.instance.activate();
  }
}

@riverpod
int? minimumBuildNumber(Ref ref) {
  final minimumBuildNumber = FirebaseRemoteConfig.instance.getInt(
    'minimumBuildNumber',
  );
  if (minimumBuildNumber == 0) {
    return null;
  }

  return minimumBuildNumber;
}
