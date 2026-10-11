import 'package:flutter/material.dart';
import '../state/app_data.dart';
import '../widgets/common.dart';
import 'bags_screen.dart';
import 'brews_screen.dart';
import 'community_screen.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';
import 'me_screen.dart';

class HomeScreen extends StatefulWidget {
  final AppData data;

  const HomeScreen({super.key, required this.data});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String? _username;

  AppData get data => widget.data;

  @override
  void initState() {
    super.initState();
    if (!data.isLoaded) data.load();
    data.services.auth.currentUsername().then((String? u) {
      if (mounted) setState(() => _username = u);
    });
  }

  Future<void> _logout() async {
    try {
      await data.services.auth.logout();
    } catch (_) {
      // Logged out locally regardless of what the server says
    }
    data.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute<void>(builder: (_) => LoginScreen(data: data)),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: data,
      builder: (BuildContext context, _) {
        // First load: spinner. Load error with nothing cached: retry screen.
        if (!data.isLoaded) {
          return Scaffold(
            body: data.error == null
                ? const Center(child: CircularProgressIndicator())
                : EmptyState(
                    icon: Icons.cloud_off_rounded,
                    title: 'Could not reach Brewlog',
                    message: 'Check that the server is running.',
                    actionLabel: 'Retry',
                    onAction: data.load,
                  ),
          );
        }

        return Scaffold(
          // IndexedStack keeps all tabs mounted so they don't reload on switch.
          body: IndexedStack(
            index: _selectedIndex,
            children: <Widget>[
              DashboardScreen(
                data: data,
                username: _username,
                onSeeAllBrews: () => setState(() => _selectedIndex = 1),
              ),
              BrewsScreen(data: data),
              BagsScreen(data: data),
              CommunityScreen(data: data),
              MeScreen(data: data, username: _username, onLogout: _logout),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) => setState(() => _selectedIndex = index),
            destinations: const <NavigationDestination>[
              NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.coffee_outlined), selectedIcon: Icon(Icons.coffee_rounded), label: 'Brews'),
              NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2_rounded), label: 'Bags'),
              NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups_rounded), label: 'Community'),
              NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Me'),
            ],
          ),
        );
      },
    );
  }
}
