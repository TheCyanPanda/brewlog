import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../models/brew.dart';
import '../services/app_services.dart';
import '../widgets/brew_card.dart';
import 'add_brew_screen.dart';

class BrewsScreen extends StatefulWidget {
  final AppServices services;

  const BrewsScreen({super.key, required this.services});

  @override
  State<BrewsScreen> createState() => _BrewsScreenState();
}

class _BrewsScreenState extends State<BrewsScreen> {
  List<Brew>? _brews;  // null = not yet loaded
  String? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBrews();
  }

  Future<void> _loadBrews() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final List<Brew> brews = await widget.services.brews.listBrews();
      if (mounted) {
        setState(() {
          _brews = brews;
          _isLoading = false;
        });
      }
    } on DioException catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Could not load brews. Is the server running?';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openAddBrew() async {
    // Wait for AddBrewScreen to close, then refresh regardless of outcome.
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => AddBrewScreen(services: widget.services),
      ),
    );
    _loadBrews();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Brews')),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddBrew,
        tooltip: 'Log a brew',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16.0),
            FilledButton(
              onPressed: _loadBrews,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_brews!.isEmpty) {
      return const Center(child: Text('No brews yet. Start brewing! ☕'));
    }

    // RefreshIndicator adds pull-to-refresh on the list.
    return RefreshIndicator(
      onRefresh: _loadBrews,
      child: ListView.builder(
        itemCount: _brews!.length,
        itemBuilder: (BuildContext context, int index) {
          return BrewCard(brew: _brews![index]);
        },
      ),
    );
  }
}
