import 'package:flutter/material.dart';

Color signInWithAppleBackgroundColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.light
      ? _signInWithAppleBlackColor
      : _signInWithAppleWhiteColor;
}

Color signInWithAppleForegroundColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.light
      ? _signInWithAppleWhiteColor
      : _signInWithAppleBlackColor;
}

const _signInWithAppleBlackColor = Color.fromARGB(255, 3, 3, 3);
const _signInWithAppleWhiteColor = Color.fromARGB(255, 255, 255, 255);
