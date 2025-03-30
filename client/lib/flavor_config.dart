import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

enum Flavor { emulator, dev, prod }

class FlavorConfig {
  factory FlavorConfig({
    required Flavor flavor,
    required String name,
    required Color color,
    FirebaseOptions? firebaseOptions,
    bool useFirebaseEmulator = false,
  }) {
    _instance ??= FlavorConfig._internal(
      flavor: flavor,
      name: name,
      color: color,
      firebaseOptions: firebaseOptions,
      useFirebaseEmulator: useFirebaseEmulator,
    );
    return _instance!;
  }

  FlavorConfig._internal({
    required this.flavor,
    required this.name,
    required this.color,
    this.firebaseOptions,
    required this.useFirebaseEmulator,
  });
  final Flavor flavor;
  final String name;
  final Color color;
  final FirebaseOptions? firebaseOptions;
  final bool useFirebaseEmulator;

  static FlavorConfig? _instance;

  static FlavorConfig get instance {
    if (_instance == null) {
      throw Exception('FlavorConfig has not been initialized');
    }
    return _instance!;
  }

  static bool get isEmulator => _instance?.flavor == Flavor.emulator;
  static bool get isDev => _instance?.flavor == Flavor.dev;
  static bool get isProd => _instance?.flavor == Flavor.prod;
}
