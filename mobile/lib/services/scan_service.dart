import 'package:dio/dio.dart';

import 'picker/picked_image.dart';

// What the backend read from a bag photo
class ScanResult {
  final Map<String, dynamic> fields; // CreateCoffeeBag-shaped, unknown fields null
  final bool demo;                   // true = example values (no API key on the server)

  const ScanResult({required this.fields, required this.demo});
}

class ScanService {
  final Dio _dio;
  ScanService(this._dio);

  // POST /bags/scan — Claude reads the label (takes a few seconds)
  Future<ScanResult> scanBag(PickedImage image) async {
    final Response<Map<String, dynamic>> response = await _dio.post<Map<String, dynamic>>(
      '/bags/scan',
      data: <String, String>{'image_base64': image.base64, 'media_type': image.mediaType},
      options: Options(receiveTimeout: const Duration(seconds: 120)),
    );
    final Map<String, dynamic> data = response.data!;
    return ScanResult(
      fields: (data['fields'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      demo: data['demo'] as bool? ?? false,
    );
  }
}
