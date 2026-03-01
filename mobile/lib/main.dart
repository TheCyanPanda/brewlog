import 'package:flutter/material.dart';

void main() {
  // runApp - inflates the widget and attaches it to the screen. const = built at compile time
  runApp(const CoffeeLogApp());
}

class CoffeeLogApp extends StatelessWidget {
  const CoffeeLogApp({super.key}); // Pass identity key to parent class

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
      home: const Scaffold( // Scaffold provieds the standard Android screen structure
        body: Center(
          child: Text('CoffeeLog'), // This is just a test. Should show 'CoffeeLog' centerd on a brown background
        ),
      ),
    );
  }
}
