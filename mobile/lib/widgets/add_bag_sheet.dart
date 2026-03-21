import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/coffee_bag.dart';
import '../services/app_services.dart';
import '../utils/string_utils.dart';


class AddBagSheet extends StatefulWidget {
  final AppServices services;
  const AddBagSheet({super.key, required this.services});

  @override
  State<AddBagSheet> createState() => _AddBagSheetState();
}

class _AddBagSheetState extends State<AddBagSheet> {
  final TextEditingController _roasterController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _regionController = TextEditingController();
  final TextEditingController _varietyController = TextEditingController();
  String? _roastLevel;
  bool _isSaving = false;

  static const List<String> _roastLevels = <String>[
    'light', 'medium-light', 'medium', 'medium-dark', 'dark',
  ];

  @override
  void dispose() {
    _roasterController.dispose();
    _countryController.dispose();
    _regionController.dispose();
    _varietyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final String roaster = _roasterController.text.trim();
    if (roaster.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Roaster is required')),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final CoffeeBag bag = await widget.services.bags.createBag(
        roaster: roaster,
        originCountry: blankToNull(_countryController.text),
        originRegion: blankToNull(_regionController.text),
        variety: blankToNull(_varietyController.text),
        roastLevel: _roastLevel,
      );
      if (mounted) Navigator.pop(context, bag);
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${e.message}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // viewInsets.bottom = keyboard height — keeps fields above the keyboard.
      padding: EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 16.0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('New Coffee Bag', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16.0),
          TextField(
            controller: _roasterController,
            decoration: const InputDecoration(labelText: 'Roaster *', border: OutlineInputBorder()),
            autofocus: true,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12.0),
          TextField(
            controller: _countryController,
            decoration: const InputDecoration(labelText: 'Country', border: OutlineInputBorder()),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12.0),
          TextField(
            controller: _regionController,
            decoration: const InputDecoration(labelText: 'Region', border: OutlineInputBorder()),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12.0),
          TextField(
            controller: _varietyController,
            decoration: const InputDecoration(labelText: 'Variety', border: OutlineInputBorder()),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12.0),
          DropdownButtonFormField<String>(
            initialValue: _roastLevel,
            decoration: const InputDecoration(labelText: 'Roast level', border: OutlineInputBorder()),
            items: _roastLevels
                .map((String l) => DropdownMenuItem<String>(value: l, child: Text(l)))
                .toList(),
            onChanged: (String? l) => setState(() => _roastLevel = l),
          ),
          const SizedBox(height: 16.0),
          FilledButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(width: 16.0, height: 16.0, child: CircularProgressIndicator(strokeWidth: 2.0))
                : const Text('Add Bag'),
          ),
        ],
      ),
    );
  }
}


