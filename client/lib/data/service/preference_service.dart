import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/data/model/preference_key.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'preference_service.g.dart';

@riverpod
PreferenceService preferenceService(Ref ref) {
  return PreferenceService();
}

class PreferenceService {
  Future<String?> getString(PreferenceKey key) {
    final preferences = SharedPreferencesAsync();
    return preferences.getString(key.name);
  }

  Future<void> setString(PreferenceKey key, {required String value}) async {
    final preferences = SharedPreferencesAsync();
    await preferences.setString(key.name, value);
  }
}
