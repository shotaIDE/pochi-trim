import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'google_form_service.g.dart';

@riverpod
GoogleFormService googleFormService(Ref ref) {
  return GoogleFormService();
}

class GoogleFormService {
  Future<void> sendFeedback({
    required String feedback,
    String? email,
    String? userId,
  }) async {
    final formData = {
      'entry.893089758': feedback,
      if (email != null && email.isNotEmpty) 'entry.1495718762': email,
      if (userId != null && userId.isNotEmpty) 'entry.1274333669': userId,
    };

    final httpClient = HttpClient();
    final uri = Uri.parse(
      'https://docs.google.com/forms/d/1FAIpQLScS1p82L5tI4frPZLggUH35sbumRxK0EHvAEScNgck1Zv7gNg/formResponse',
    );

    final request = await httpClient.postUrl(uri);
    request.headers.set('Content-Type', 'application/x-www-form-urlencoded');

    final body = formData.entries
        .map((entry) => '${entry.key}=${Uri.encodeComponent(entry.value)}')
        .join('&');

    request.write(body);

    final response = await request.close();

    await response.drain<void>();
    httpClient.close();
  }
}
