import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/roaster_home_screen.dart';
import 'services/api_client.dart';
import 'services/app_services.dart';
import 'state/app_data.dart';
import 'theme.dart';

// Global navigation key — lets the auth interceptor navigate to login
// without needing a BuildContext.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  // `late` allows the onUnauthorized closure to capture `data` before
  // it's assigned — by the time a 401 fires, the assignment is long done.
  late final AppData data;

  final Dio dio = createApiClient(
    onUnauthorized: () {
      data.clear();
      // Clear the entire back stack and send the user to login.
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => LoginScreen(data: data),
        ),
        (_) => false,
      );
    },
  );

  data = AppData(AppServices.fromDio(dio));

  runApp(BrewlogApp(data: data));
}

class BrewlogApp extends StatelessWidget {
  final AppData data;

  const BrewlogApp({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Brewlog',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      // On wide screens (laptop browser) keep the app phone-sized and centered.
      builder: (BuildContext context, Widget? child) => ColoredBox(
        color: const Color(0xFF0E0906),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: child,
          ),
        ),
      ),
      home: StartupRouter(data: data),
    );
  }
}

/// Shown on launch. Checks local storage for a saved token and routes
/// to [HomeScreen] or [LoginScreen] accordingly.
class StartupRouter extends StatelessWidget {
  final AppData data;

  const StartupRouter({super.key, required this.data});

  // (has a saved token, account role)
  Future<(bool, String)> _session() async =>
      (await data.services.auth.isLoggedIn(), await data.services.auth.currentRole());

  @override
  Widget build(BuildContext context) {
    // FutureBuilder rebuilds when the async check completes.
    return FutureBuilder<(bool, String)>(
      future: _session(),
      builder: (BuildContext context, AsyncSnapshot<(bool, String)> snapshot) {
        // Still waiting for SharedPreferences to respond.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Token found — go straight home (roaster accounts to the roaster portal).
        final (bool loggedIn, String role) = snapshot.data ?? (false, 'user');
        if (loggedIn) {
          return role == 'roaster' ? RoasterHomeScreen(data: data) : HomeScreen(data: data);
        }

        // No token — user must log in.
        return LoginScreen(data: data);
      },
    );
  }
}
