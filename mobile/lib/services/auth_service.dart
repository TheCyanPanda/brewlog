import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Key for storing the token in local storage
const String _kTokenKey = 'auth_token';

class AuthService {
  // Dio instance is injected (not created here)
  final Dio _dio;
  AuthService(this._dio);


  // Check if user auth token is already saved locally.
  // Decides what to show on startup: LoginScreen or HomeScreen
  Future<bool> isLoggedIn() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kTokenKey) != null;
  }

  // POST /auth/login
  // Sends credentials and received a bearer token, saves it locally.
  // Trow 401 wrong password on network error (LoginScreen should catch and act on error)
  Future<void> login(String username, String password) async {
    final Response<Map<String, dynamic>> response =
      await _dio.post<Map<String, dynamic>> (
        '/auth/login',
        data: <String, String> {
          'username': username,
          'password': password,
        },
      );

    // Extract the token from response body: {"token": "S0meC00lP4$$w0rdYO!"}
    final String? token = response.data?['token'] as String?;
    if (token == null) {
      throw Exception('Login response missing token field');
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTokenKey, token);
  }

  // POST /auth/logout - tells the backend to revoke the token.
  // We clear local storage regardless if the server calls success or not, so that the user
  // remains logged out.
  Future<void> logout() async {
    try {
      await _dio.post<void>('/auth/logout');
    } finally {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kTokenKey);
    }
  }

  // POST /auth/register
  // Create new account. Does not log in automatically - send to login screen after register
  Future<void> register(String username, String password) async {
    await _dio.post<void>(
      '/auth/register',
      data: <String, String> {
        'username': username,
        'password': password
      },
    );
  }

}
