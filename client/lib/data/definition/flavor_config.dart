import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:pochi_trim/data/definition/flavor.dart';

class FlavorConfig {
  factory FlavorConfig({
    required Flavor flavor,
    required String name,
    required Color color,
    FirebaseOptions? firebaseOptions,
  }) {
    _instance ??= FlavorConfig._internal(
      flavor: flavor,
      name: name,
      color: color,
      firebaseOptions: firebaseOptions,
    );
    return _instance!;
  }

  FlavorConfig._internal({
    required this.flavor,
    required this.name,
    required this.color,
    this.firebaseOptions,
  });
  final Flavor flavor;
  final String name;
  final Color color;
  final FirebaseOptions? firebaseOptions;

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
