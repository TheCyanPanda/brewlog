import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../models/brew.dart';
import '../services/brew_service.dart';
import '../widgets/brew_card.dart';

class BrewsScreen extends StatefulWidget {
  final BrewService brewService;

  const BrewsScreen({super.key, required this.brewService});

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
    // Kick off the fetch as soon as the screen is inserted into the tree.
    _loadBrews();
  }

  Future<void> _loadBrews() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final List<Brew> brews = await widget.brewService.listBrews();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Brews')),
      body: _buildBody(),
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
            // Pull-to-retry button
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

    // RefreshIndicator adds pull-to-refresh on the list
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

