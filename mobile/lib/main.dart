import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/api_client.dart';
import 'services/app_services.dart';

// Global navigation key — lets the auth interceptor navigate to login
// without needing a BuildContext.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  // `late` allows the onUnauthorized closure to capture `services` before
  // it's assigned — by the time a 401 fires, the assignment is long done.
  late final AppServices services;

  final Dio dio = createApiClient(
    onUnauthorized: () {
      // Clear the entire back stack and send the user to login.
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => LoginScreen(services: services),
        ),
        (_) => false,
      );
    },
  );

  services = AppServices.fromDio(dio);

  runApp(CoffeeLogApp(services: services));
}

class CoffeeLogApp extends StatelessWidget {
  final AppServices services;

  const CoffeeLogApp({super.key, required this.services});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CoffeeLog',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6F4E37), // coffee brown
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: StartupRouter(services: services),
    );
  }
}

/// Shown on launch. Checks local storage for a saved token and routes
/// to [HomeScreen] or [LoginScreen] accordingly.
class StartupRouter extends StatelessWidget {
  final AppServices services;

  const StartupRouter({super.key, required this.services});

  @override
  Widget build(BuildContext context) {
    // FutureBuilder rebuilds when the async check completes.
    return FutureBuilder<bool>(
      future: services.auth.isLoggedIn(),
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        // Still waiting for SharedPreferences to respond.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Token found — go straight home.
        if (snapshot.data == true) {
          return HomeScreen(services: services);
        }

        // No token — user must log in.
        return LoginScreen(services: services);
      },
    );
  }
}
