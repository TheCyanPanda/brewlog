import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Base URL of the backend (leading 'k' is for constant). Override at build time with
// --dart-define=API_BASE_URL=http://host:port
// Defaults: on web the PWA is served by the backend itself, so use the same origin.
// On Android emulator, 10.0.2.2 is the alias for the host machine's localhost.
const String _kApiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');
final String kbaseUrl = _kApiBaseUrlOverride.isNotEmpty
    ? _kApiBaseUrlOverride
    : (kIsWeb ? Uri.base.origin : 'http://10.0.2.2:3001');

// Called by the interceptor when a 401 (Unauthorized error) is received.
// Navigates to login (e.g expired/invalid token)
typedef OnUnauthorizedCallback = void Function();

// A single shared Dio instance for the whole App
// Args:
// onUnauthorized: callback function on 401 errors
Dio createApiClient({OnUnauthorizedCallback? onUnauthorized}) {
  // Options for our dio API client
  final BaseOptions options = BaseOptions(
    baseUrl: kbaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: <String, String> {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  );

  final Dio dio = Dio(options);
  dio.interceptors.add(AuthInterceptor(onUnauthorized: onUnauthorized));
  return dio;
}

// This runs before every request and after every response.
// It attaches the bearer token to outgoing requests and catches 401 resoness and clears the token
// (if backend rejected it)
class AuthInterceptor extends Interceptor {
  final OnUnauthorizedCallback? onUnauthorized;
  AuthInterceptor({this.onUnauthorized}); // 401

  // Called before every requrest is sent
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Load the saved token from local storage
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('auth_token');

    // If we have a token, attach it as Bearer header
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // Pass the request along the chain
    handler.next(options);
  }

  // Called when a reposnse comes back with error status
  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // 401 Unauthorized - the token is missing, expired or revied.
    // Clear it from storage so the app will redirect to login next time
    if (err.response?.statusCode == 401) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      onUnauthorized?.call(); // Triggers navigation
    }

    handler.next(err);
  }
}
