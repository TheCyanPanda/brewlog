import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/brew_service.dart';
import 'bags_screen.dart';
import 'brews_screen.dart';

class HomeScreen extends StatefulWidget {
  final AuthService authService;
  final Dio dio;
  final BrewService brewService;

  const HomeScreen(
    {
      super.key,
      required this.authService,
      required this.dio,
      required this.brewService,
    }
  );


  @override
  State<HomeScreen> createState() => _HomeScreenState();

}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Each tab is its own widget
  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = <Widget>[
      // Dashboard
      const Center(child: Text('Dashboard - coming soon')), // TODO: Fix placeholder
      // Brews list
      BrewsScreen(brewService: widget.brewService),
      // Bags
      BagsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack( // Keeps tabs visible during scrolling + no reload on tab switching
        index: _selectedIndex,
        children: _tabs,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.coffee_outlined),
            selectedIcon: Icon(Icons.coffee),
            label: 'Brews',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Bags',
          ),
        ],
      ),
    );
  }

}
