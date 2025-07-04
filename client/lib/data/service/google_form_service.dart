import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:pochi_trim/data/model/feedback_request.dart';
import 'package:pochi_trim/data/model/send_feedback_exception.dart';
import 'package:pochi_trim/data/service/dao/feedback_request_post.dart';
import 'package:pochi_trim/data/service/error_report_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'google_form_service.g.dart';

@riverpod
GoogleFormService googleFormService(Ref ref) {
  final dio = ref.watch<Dio>(dioProvider);
  final errorReportService = ref.watch(errorReportServiceProvider);

  return GoogleFormService(dio: dio, errorReportService: errorReportService);
}

@riverpod
Dio dio(Ref ref) {
  return Dio();
}

class GoogleFormService {
  GoogleFormService({
    required Dio dio,
    required ErrorReportService errorReportService,
  }) : _dio = dio,
       _errorReportService = errorReportService;

  final Dio _dio;
  final ErrorReportService _errorReportService;

  final _logger = Logger('GoogleFormService');

  /// フィードバックをGoogle Formに送信する
  ///
  /// Throws:
  /// - [SendFeedbackException]: リクエストに失敗した場合
  Future<void> sendFeedback(FeedbackRequest request) async {
    final requestPost = FeedbackRequestPost.fromFeedbackRequest(request);
    final formData = requestPost.toFormData();

    const url =
        'https://docs.google.com/forms/d/e/1FAIpQLScS1p82L5tI4frPZLggUH35sbumRxK0EHvAEScNgck1Zv7gNg/formResponse';

    try {
      await _dio.post<void>(
        url,
        data: formData,
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
        ),
      );
    } on DioException catch (e, stack) {
      _logger.severe('Failed to send feedback', e);

      if (e.type == DioExceptionType.unknown) {
        unawaited(_errorReportService.recordError(e, stack));

        throw const SendFeedbackException.uncategorized();
      }

      throw const SendFeedbackException.connection();
    } on SocketException {
      throw const SendFeedbackException.connection();
    }
  }
}
