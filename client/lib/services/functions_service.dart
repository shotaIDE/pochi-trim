import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/models/generate_my_house_result.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'functions_service.g.dart';

@riverpod
Future<String?> generateMyHouse(Ref ref) async {
  final logger = Logger('FunctionsService');

  try {
    final functions = FirebaseFunctions.instance;
    final callable = functions.httpsCallable('generate_my_house');
    final result = await callable.call<GenerateMyHouseResult>();

    debugPrint('Cloud Function Response: ${result.data}');
    logger.info('generate_my_house APIの呼び出しに成功しました: ${result.data}');
  } catch (apiError) {
    debugPrint('Cloud Function Error: $apiError');
    logger.warning('generate_my_house APIの呼び出しに失敗しました: $apiError');
  }
  return null;
}
