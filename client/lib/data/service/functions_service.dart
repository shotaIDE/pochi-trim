import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:pochi_trim/data/model/generate_my_house_exception.dart';
import 'package:pochi_trim/data/service/dao/generate_my_house_result_functions.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'functions_service.g.dart';

@riverpod
Future<String> generateMyHouse(Ref ref) async {
  final logger = Logger('FunctionsService');

  final functions = FirebaseFunctions.instance;
  final callable = functions.httpsCallable('generate_my_house');

  final HttpsCallableResult<Map<String, dynamic>> rawResult;
  try {
    rawResult = await callable.call<Map<String, dynamic>>();
  } on FirebaseFunctionsException catch (e) {
    logger.info('Call error: ${e.code}');

    throw GenerateMyHouseException();
  }

  final result = GenerateMyHouseResultFunctions.fromJson(rawResult.data);
  final houseId = result.houseDocId;

  logger.info('Got house ID: $houseId');

  return houseId;
}

@riverpod
Future<void> deleteHouseWork(
  Ref ref,
  String houseId,
  String houseWorkId,
) async {
  final logger = Logger('FunctionsService');

  final functions = FirebaseFunctions.instance;
  final callable = functions.httpsCallable('delete_house_work');

  try {
    await callable.call<Map<String, dynamic>>({
      'houseId': houseId,
      'houseWorkId': houseWorkId,
    });
    logger.info('Successfully deleted house work: $houseWorkId');
  } on FirebaseFunctionsException catch (e) {
    logger.severe('Failed to delete house work: ${e.code} - ${e.message}');
    throw Exception('家事の削除に失敗しました: ${e.message}');
  }
}
