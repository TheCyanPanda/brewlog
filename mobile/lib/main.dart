import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';


void main() {
  final Dio dio = createApiClient();
  final AuthService authService = AuthService(dio);

  // runApp - inflates the widget and attaches it to the screen. const = built at compile time
  runApp(CoffeeLogApp(dio: dio, authService: authService));
}

class CoffeeLogApp extends StatelessWidget {
  final Dio dio;
  final AuthService authService;
  const CoffeeLogApp(
    {
      super.key,
      required this.dio,
      required this.authService,
    }
  ); // Pass identity key to parent class

  @override
  Widget build(BuildContext context) {
  // build() is called by the framework whenever this widget needs to render - always returns a Widget.
  return MaterialApp( // Top lelvel widget that sets up naivation, theming etc
      title: 'CoffeeLog',
      // hide the red "DEBUG" banner in the corner
      debugShowCheckedModeBanner: false,

      // Color Schema in app
      theme: ThemeData(
        //fromSeed generates a full color pallete from a seed color
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6F4E37), // Brown
          brightness: Brightness.dark // Dark mode
        ),
        useMaterial3: true
      ),

      // home is the first screen shown on app launch
      home: StartupRouter(dio: dio, authService: authService)
    );
  }
}

// Shown on laugn, checks local storage for a saved login token and route to screen
class StartupRouter extends StatelessWidget {
  final Dio dio;
  final AuthService authService;

  const StartupRouter(
    {
      super.key,
      required this.dio,
      required this.authService,
    }
  );

  @override
  Widget build(BuildContext context) {
    // Rebuilds when an async Future completes. <bool> is the return type of 'isLoggedIn'
    return FutureBuilder<bool> (
      future: authService.isLoggedIn(),
        builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
          // ConnectionState.waiting = Future has not resolved yet
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

        // Token found in local storage: Go straight home
        if (snapshot.data == true) {
          return HomeScreen(dio: dio, authService: authService);
        }

        // No token: User must log in
        return LoginScreen(dio: dio, authService: authService);
      },
    );
  }
}
