import 'package:dio/dio.dart';

import '../models/brew.dart';

class BrewService {
  final Dio _dio;

  BrewService(this._dio);

  // GET /brews — returns the most recent brews.
  Future<List<Brew>> listBrews({int limit = 20, int offset = 0}) async {
    final Response<List<dynamic>> response = await _dio.get<List<dynamic>>(
      '/brews',
      queryParameters: <String, dynamic>{
        'limit': limit,
        'offset': offset,
      },
    );

    final List<dynamic> data = response.data ?? <dynamic>[];

    // Cast each item to a Map and deserialise into a Brew
    return data
        .cast<Map<String, dynamic>>()
        .map(Brew.fromJson)
        .toList();
  }
}

//TODO : Auto update brews to screen
