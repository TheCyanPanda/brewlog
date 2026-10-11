import 'package:dio/dio.dart';

import '../models/brew.dart';

class BrewService {
  final Dio _dio;

  BrewService(this._dio);

  // GET /brews — returns the most recent brews.
  Future<List<Brew>> listBrews({int limit = 500, int offset = 0}) async {
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

  // POST /brews — all fields optional; pass only what the user filled in.
  Future<Brew> createBrew({
    int? coffeeBagId,
    int? brewerId,
    int? grinderId,
    int? recipeId,
    String? grindSetting,
    String? filterPaper,
    double? coffeeGrams,
    double? waterGrams,
    double? waterTempC,
    int? brewTimeSecs,   // caller converts MM:SS → seconds
    List<BrewStep>? brewSteps,
    DateTime? brewDatetime, // defaults to now on the backend
    String? rating,
    String? review,
    String? notes,
  }) async {
    final Response<Map<String, dynamic>> response =
        await _dio.post<Map<String, dynamic>>(
      '/brews',
      // Null values are omitted by Dio so the backend uses its own defaults.
      data: <String, dynamic>{
        'coffee_bag_id': coffeeBagId,
        'brewer_id': brewerId,
        'grinder_id': grinderId,
        'recipe_id': recipeId,
        'grind_setting': grindSetting,
        'filter_paper': filterPaper,
        'coffee_grams': coffeeGrams,
        'water_grams': waterGrams,
        'water_temp_c': waterTempC,
        'brew_time_secs': brewTimeSecs,
        'brew_steps': brewSteps?.map((BrewStep s) => s.toJson()).toList(),
        'brew_datetime': brewDatetime?.toUtc().toIso8601String(),
        'rating': rating,
        'review': review,
        'notes': notes,
      },
    );
    return Brew.fromJson(response.data!);
  }

  // DELETE /brews/:id
  Future<void> deleteBrew(int id) async {
    await _dio.delete<void>('/brews/$id');
  }
}
