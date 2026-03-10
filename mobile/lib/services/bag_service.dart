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
  /* TODO: Add option to add image of bag */
/*  Future<CoffeeBag> createBag({
    String roaster,
    String? roasterOriginCity,
    String? roasterOriginCountry,
    String? originCountry,
    String? originRegion,
    String roastLevel, // TODO: Make this selectable so that we can easily filter later on
    String? variety,
  }) async {
    final Response<Map<String, dynamic>> response =
        await _dio.post<Map<String, dynamic>>(
          '/bags',
          data: <String, dynamic>{
            'roaster': roaster,
          },
        );
    return CoffeeBag.fromJson(response.data!);
  }*/
}
