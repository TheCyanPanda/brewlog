import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../widgets/bag_card.dart';
import '../models/coffee_bag.dart';
import '../services/app_services.dart';
import '../widgets/add_bag_sheet.dart';


class BagsScreen extends StatefulWidget {
  final AppServices services;

  const BagsScreen({super.key, required this.services});

  @override
  State<BagsScreen> createState() => _BagsScreenState();
}

class _BagsScreenState extends State<BagsScreen> {
  List<CoffeeBag>? _bags; // List of Coffee bags. null = not loaded
  String? _error;
  bool _isLoading = true;  // If bags are waiting to be loaded

  @override
  void initState() {
    super.initState();
    _loadBags();
  }

  Future<void> _loadBags() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

      // GET /bags and assign result to _bags
      try {
        final List<CoffeeBag> bags = await widget.services.bags.listBags();
        if (mounted) {
          setState(() {
            _bags = bags;
            _isLoading = false;
          });
        }
      } on DioException catch(_) { // TODO: Should we really catch all ?
        if (mounted) {
          setState(() {
            _error = "Error loading bags. Is the server running?";
            _isLoading = false;
          });
        }
      }
    }

  // '+ Add bag'
  Future<void> _openAddBag() async {
    final CoffeeBag? newBag = await showModalBottomSheet<CoffeeBag>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddBagSheet(services: widget.services),
    );
    if (newBag != null) _loadBags();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My bags')),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddBag,
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
            FilledButton(onPressed: _loadBags, child: const Text('Retry')),
          ]
        )
      );
    }

    if (_bags!.isEmpty) {
      return const Center(child: Text("No bags yet"));
    }

    // RefreshIndicator adds pull-to-refresh on the list.
    return RefreshIndicator(
      onRefresh: _loadBags,
      child: ListView.builder(
        itemCount: _bags!.length,
        itemBuilder: (BuildContext context, int index) {
          return BagCard(bag: _bags![index]);
        },
      ),
    );
  }


}
