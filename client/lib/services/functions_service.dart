import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/services/dao/generate_my_house_result_functions.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'functions_service.g.dart';

class GenerateMyHouseException implements Exception {}

@riverpod
Future<String> generateMyHouse(Ref ref) async {
  final logger = Logger('FunctionsService');

  final functions = FirebaseFunctions.instance;
  final callable = functions.httpsCallable('generate_my_house');

  final HttpsCallableResult<GenerateMyHouseResultFunctions> result;
  try {
    result = await callable.call<GenerateMyHouseResultFunctions>();
  } on FirebaseFunctionsException catch (e) {
    logger.info('Call error: ${e.code}');

    throw GenerateMyHouseException();
  }

  final houseId = result.data.houseDocId;

  logger.info('Got house ID: $houseId');

  return houseId;
}
