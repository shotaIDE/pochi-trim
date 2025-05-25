import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pochi_trim/data/model/preference_key.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'preference_service.g.dart';

@riverpod
PreferenceService preferenceService(Ref ref) {
  return PreferenceService();
}

class PreferenceService {
  Future<bool?> getBool(PreferenceKey key) {
    final preferences = SharedPreferencesAsync();
    return preferences.getBool(key.name);
  }

  Future<void> setBool(PreferenceKey key, {required bool value}) async {
    final preferences = SharedPreferencesAsync();
    await preferences.setBool(key.name, value);
  }

  Future<String?> getString(PreferenceKey key) {
    final preferences = SharedPreferencesAsync();
    return preferences.getString(key.name);
  }

  Future<void> setString(PreferenceKey key, {required String value}) async {
    final preferences = SharedPreferencesAsync();
    await preferences.setString(key.name, value);
  }
}
