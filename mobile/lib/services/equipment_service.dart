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

  Future<Grinder> createGrinder(String name, {String? notes, DateTime? purchasedAt}) async {
    final Response<Map<String, dynamic>> response =
    await _dio.post<Map<String, dynamic>>(
      '/grinders',
      data: <String, dynamic>{
        'name': name,
        'notes': notes,
        'purchased_at': purchasedAt?.toIso8601String().substring(0, 10),
      },
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
    DateTime? purchasedAt,
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
        'purchased_at': purchasedAt?.toIso8601String().substring(0, 10),
      },
    );
    return Brewer.fromJson(response.data!);
  }

  // POST /grinders/:id/maintenance — mark as cleaned now
  Future<Grinder> markGrinderCleaned(int id) async {
    final Response<Map<String, dynamic>> response = await _dio.post<Map<String, dynamic>>(
      '/grinders/$id/maintenance',
      data: <String, String>{'action': 'cleaned'},
    );
    return Grinder.fromJson(response.data!);
  }

  // POST /brewers/:id/maintenance — action: 'cleaned' | 'descaled'
  Future<Brewer> markBrewerMaintenance(int id, String action) async {
    final Response<Map<String, dynamic>> response = await _dio.post<Map<String, dynamic>>(
      '/brewers/$id/maintenance',
      data: <String, String>{'action': action},
    );
    return Brewer.fromJson(response.data!);
  }
}
