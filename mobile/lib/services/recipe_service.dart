import 'package:dio/dio.dart';

import '../models/brew.dart';
import '../models/recipe.dart';

class RecipeService {
  final Dio _dio;
  RecipeService(this._dio);

  // GET /recipes — default recipe first
  Future<List<Recipe>> listRecipes() async {
    final Response<List<dynamic>> response = await _dio.get<List<dynamic>>('/recipes');
    return (response.data ?? <dynamic>[])
        .cast<Map<String, dynamic>>()
        .map(Recipe.fromJson)
        .toList();
  }

  // POST /recipes
  Future<Recipe> createRecipe({
    required String name,
    String? brewType,
    double? coffeeGrams,
    double? waterGrams,
    double? waterTempC,
    int? brewTimeSecs,
    List<BrewStep>? steps,
    String? notes,
    String? source,
    bool isDefault = false,
  }) async {
    final Response<Map<String, dynamic>> response = await _dio.post<Map<String, dynamic>>(
      '/recipes',
      data: <String, dynamic>{
        'name': name,
        'brew_type': ?brewType,
        'coffee_grams': ?coffeeGrams,
        'water_grams': ?waterGrams,
        'water_temp_c': ?waterTempC,
        'brew_time_secs': ?brewTimeSecs,
        'steps': ?steps?.map((BrewStep s) => s.toJson()).toList(),
        'notes': ?notes,
        'source': ?source,
        'is_default': isDefault,
      },
    );
    return Recipe.fromJson(response.data!);
  }

  // DELETE /recipes/:id
  Future<void> deleteRecipe(int id) async {
    await _dio.delete<void>('/recipes/$id');
  }
}
