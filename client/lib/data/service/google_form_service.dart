import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:pochi_trim/data/model/feedback_request.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'google_form_service.g.dart';

@riverpod
GoogleFormService googleFormService(Ref ref) {
  final dio = ref.watch<Dio>(dioProvider);
  return GoogleFormService(dio);
}

@riverpod
Dio dio(Ref ref) {
  return Dio();
}

class GoogleFormService {
  const GoogleFormService(this._dio);

  final Dio _dio;

  Future<void> sendFeedback(FeedbackRequest request) async {
    final logger = Logger('GoogleFormService');

    final formData = {
      'entry.893089758': request.feedback,
      if (request.email != null && request.email!.isNotEmpty)
        'entry.1495718762': request.email,
      if (request.userId != null && request.userId!.isNotEmpty)
        'entry.1274333669': request.userId,
    };

    const url =
        'https://docs.google.com/forms/d/e/1FAIpQLScS1p82L5tI4frPZLggUH35sbumRxK0EHvAEScNgck1Zv7gNg/formResponse';

    logger.info(url);
    logger.info('Sending feedback to Google Form');

    final response = await _dio.post<void>(
      url,
      data: formData,
      options: Options(
        contentType: 'application/x-www-form-urlencoded',
      ),
    );

    logger.info(
      'Google Form response: status=${response.statusCode}, statusMessage=${response.statusMessage}',
    );
  }
}
