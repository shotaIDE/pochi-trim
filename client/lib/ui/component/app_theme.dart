import 'package:flutter/material.dart';

const seedColor = Color.fromRGBO(0, 122, 136, 1);

ThemeData getLightTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
  );
}

ThemeData getDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    ),
  );
}
