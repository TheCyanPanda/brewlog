import 'package:flutter/material.dart';
import '../services/app_services.dart';
import 'bags_screen.dart';
import 'brews_screen.dart';

class HomeScreen extends StatefulWidget {
  final AppServices services;

  const HomeScreen({super.key, required this.services});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Each tab is its own widget — built once and kept alive by IndexedStack.
  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = <Widget>[
      const Center(child: Text('Dashboard — coming soon')), // TODO: dashboard
      BrewsScreen(services: widget.services),
      BagsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack keeps all tabs mounted so they don't reload on switch.
      body: IndexedStack(
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
