import 'dart:typed_data';

import 'package:dio/dio.dart';
import '../models/coffee_bag.dart';

class BagService {
  final Dio _dio;

  BagService(this._dio);

  // GET /bags
  Future<List<CoffeeBag>> listBags() async {
    final Response<List<dynamic>> response =
    await _dio.get<List<dynamic>>('/bags');
    return (response.data ?? <dynamic>[])
        .cast<Map<String, dynamic>>()
        .map(CoffeeBag.fromJson)
        .toList();
  }

  // POST /bags
  /* TODO: Add option to make originCountry take multuple counties  (everyone
  does not only drink single origin, hey!) */
  Future<CoffeeBag> createBag({
    required String roaster,
    String? roasterOriginCity,
    String? roasterOriginCountry,
    String? originCountry,
    String? originRegion,
    String? roastLevel, // TODO: Make this selectable so that we can easily filter later on
    String? variety,
    String? process,
    List<String>? tasteNotes,
    String? beanType,
    DateTime? harvestDate,
    DateTime? roastDate,
    bool caffeineFree = false,
    String? batchId,
    String status = 'opened',

  }) async {
    final Response<Map<String, dynamic>> response =
        await _dio.post<Map<String, dynamic>>(
          '/bags',
          data: <String, dynamic>{
            'roaster': roaster,
            'roaster_origin_city': ?roasterOriginCity,
            'roaster_origin_country': ?roasterOriginCountry,
            'origin_country': ?originCountry,
            'origin_region': ?originRegion,
            'roast_level': ?roastLevel,
            'variety': ?variety,
            'process': ?process,
            'taste_notes': ?tasteNotes,
            'bean_type': ?beanType,
            'harvest_date': ?_date(harvestDate),
            'roast_date': ?_date(roastDate),
            'caffeine_free': caffeineFree,
            'batch_id': ?batchId,
            'status': status,
          },
        );
    return CoffeeBag.fromJson(response.data!);
  }

  // PUT /bags/:id — send the full bag (see CoffeeBag.toJson for overrides)
  Future<CoffeeBag> updateBag(int id, Map<String, dynamic> body) async {
    final Response<Map<String, dynamic>> response =
        await _dio.put<Map<String, dynamic>>('/bags/$id', data: body);
    return CoffeeBag.fromJson(response.data!);
  }

  // GET /bags/photos — ids of bags that have a photo
  Future<Set<int>> listPhotoIds() async {
    final Response<List<dynamic>> response = await _dio.get<List<dynamic>>('/bags/photos');
    return (response.data ?? <dynamic>[]).cast<int>().toSet();
  }

  // GET /bags/:id/photo — raw image bytes
  Future<Uint8List> getPhoto(int id) async {
    final Response<List<int>> response = await _dio.get<List<int>>(
      '/bags/$id/photo',
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data!);
  }

  // PUT /bags/:id/photo — raw image bytes with their Content-Type
  Future<void> putPhoto(int id, Uint8List bytes, String mediaType) async {
    await _dio.put<void>(
      '/bags/$id/photo',
      data: Stream<List<int>>.value(bytes),
      options: Options(contentType: mediaType, headers: <String, Object>{Headers.contentLengthHeader: bytes.length}),
    );
  }

  // Backend expects plain dates: "2026-09-21"
  static String? _date(DateTime? d) => d?.toIso8601String().substring(0, 10);
}
