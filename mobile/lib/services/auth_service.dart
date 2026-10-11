import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Keys for storing the token and username in local storage
const String _kTokenKey = 'auth_token';
const String _kUsernameKey = 'username';
const String _kRoleKey = 'role';                // 'user' | 'roaster'
const String _kRoasterNameKey = 'roaster_name';

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
  // Returns the account role: 'user' or 'roaster'
  Future<String> login(String username, String password) async {
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
    await prefs.setString(_kUsernameKey, username);
    final String role = response.data?['role'] as String? ?? 'user';
    await prefs.setString(_kRoleKey, role);
    final String? roasterName = response.data?['roaster_name'] as String?;
    if (roasterName != null) {
      await prefs.setString(_kRoasterNameKey, roasterName);
    } else {
      await prefs.remove(_kRoasterNameKey);
    }
    return role;
  }

  // Role of the logged-in account, saved at login ('user' if unknown)
  Future<String> currentRole() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kRoleKey) ?? 'user';
  }

  // Username of the logged-in user (saved at login), for display
  Future<String?> currentUsername() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kUsernameKey);
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
      await prefs.remove(_kUsernameKey);
      await prefs.remove(_kRoleKey);
      await prefs.remove(_kRoasterNameKey);
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
