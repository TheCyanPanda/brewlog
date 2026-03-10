import 'package:dio/dio.dart';
import '../models/equipment.dart';

class EquipmentService {
  final Dio _dio;
  EquipmentService(this._dio);

  Future<List<Grinder>> listGrinders() async {
    final Response<List<dynamic>> response =
    await _dio.get<List<dynamic>>('/grinders');
    return (response.data ?? <dynamic>[])
        .cast<Map<String, dynamic>>()
        .map(Grinder.fromJson)
        .toList();
  }

  Future<List<Brewer>> listBrewers() async {
    final Response<List<dynamic>> response =
    await _dio.get<List<dynamic>>('/brewers');
    return (response.data ?? <dynamic>[])
        .cast<Map<String, dynamic>>()
        .map(Brewer.fromJson)
        .toList();
  }

  Future<Grinder> createGrinder(String name, {String? notes}) async {
    final Response<Map<String, dynamic>> response =
    await _dio.post<Map<String, dynamic>>(
      '/grinders',
      data: <String, dynamic>{'name': name, 'notes': notes},
    );
    return Grinder.fromJson(response.data!);
  }

  Future<Brewer> createBrewer({
    required String name,
    required String brewMethod,
    String? brewType,
    String? brand,
    String? model,
    String? notes,
  }) async {
    final Response<Map<String, dynamic>> response =
    await _dio.post<Map<String, dynamic>>(
      '/brewers',
      data: <String, dynamic>{
        'name': name,
        'brew_method': brewMethod,
        'brew_type': brewType,
        'brand': brand,
        'model': model,
        'notes': notes,
      },
    );
    return Brewer.fromJson(response.data!);
  }
}
