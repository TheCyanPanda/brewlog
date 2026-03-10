import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../models/coffee_bag.dart';
import '../models/equipment.dart';
import '../services/app_services.dart';

class AddBrewScreen extends StatefulWidget {
  final AppServices services;

  const AddBrewScreen({super.key, required this.services});

  @override
  State<AddBrewScreen> createState() => _AddBrewScreenState();
}

class _AddBrewScreenState extends State<AddBrewScreen> {
  // Dropdown data
  bool _isLoadingData = true;
  String? _loadError;

  List<CoffeeBag> _bags = <CoffeeBag>[];
  List<Brewer> _brewers = <Brewer>[];
  List<Grinder> _grinders = <Grinder>[];

  // Selected values
  CoffeeBag? _selectedBag;
  Brewer? _selectedBrewer;
  Grinder? _selectedGrinder;
  String? _selectedRating;

  // Text controllers
  final TextEditingController _coffeeGramsController = TextEditingController();
  final TextEditingController _waterGramsController = TextEditingController();
  final TextEditingController _waterTempController = TextEditingController();
  final TextEditingController _brewTimeController = TextEditingController(); // MM:SS
  final TextEditingController _notesController = TextEditingController();

  // Advanced section
  bool _showAdvanced = false;
  final TextEditingController _grindSettingController = TextEditingController();
  final TextEditingController _filterPaperController = TextEditingController();
  final TextEditingController _reviewController = TextEditingController();

  bool _isSaving = false;

  static const List<String> _ratingOptions = <String>[
    'excellent',
    'good',
    'ok',
    'bad',
  ];

  @override
  void initState() {
    super.initState();
    _loadDropdowns();
  }

  @override
  void dispose() {
    _coffeeGramsController.dispose();
    _waterGramsController.dispose();
    _waterTempController.dispose();
    _brewTimeController.dispose();
    _notesController.dispose();
    _grindSettingController.dispose();
    _filterPaperController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  // Load bags, brewers, and grinders in parallel.
  Future<void> _loadDropdowns() async {
    try {
      final List<Object> results = await Future.wait<Object>(<Future<Object>>[
        widget.services.bags.listBags(),
        widget.services.equipment.listBrewers(),
        widget.services.equipment.listGrinders(),
      ]);
      if (mounted) {
        setState(() {
          _bags = results[0] as List<CoffeeBag>;
          _brewers = results[1] as List<Brewer>;
          _grinders = results[2] as List<Grinder>;
          _isLoadingData = false;
        });
      }
    } on DioException catch (_) {
      if (mounted) {
        setState(() {
          _loadError = 'Could not load data. Is the server running?';
          _isLoadingData = false;
        });
      }
    }
  }

  // Convert "MM:SS" to seconds. Also accepts a plain integer (raw seconds).
  int? _parseBrewTime(String text) {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    final List<String> parts = trimmed.split(':');
    if (parts.length == 2) {
      final int? mins = int.tryParse(parts[0]);
      final int? secs = int.tryParse(parts[1]);
      if (mins != null && secs != null) return mins * 60 + secs;
    }
    return int.tryParse(trimmed); // fallback: treat as raw seconds
  }

  // Return null for empty strings so the backend treats them as absent.
  String? _blankToNull(String s) => s.trim().isEmpty ? null : s.trim();

  Future<void> _submit() async {
    setState(() => _isSaving = true);
    try {
      await widget.services.brews.createBrew(
        coffeeBagId: _selectedBag?.id,
        brewerId: _selectedBrewer?.id,
        grinderId: _selectedGrinder?.id,
        grindSetting: _blankToNull(_grindSettingController.text),
        filterPaper: _blankToNull(_filterPaperController.text),
        coffeeGrams: double.tryParse(_coffeeGramsController.text.trim()),
        waterGrams: double.tryParse(_waterGramsController.text.trim()),
        waterTempC: double.tryParse(_waterTempController.text.trim()),
        brewTimeSecs: _parseBrewTime(_brewTimeController.text),
        rating: _selectedRating,
        review: _blankToNull(_reviewController.text),
        notes: _blankToNull(_notesController.text),
      );
      if (mounted) Navigator.pop(context);
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: ${e.message}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Brew'),
        actions: <Widget>[
          // Save button in the app bar — disabled while saving.
          if (!_isLoadingData && _loadError == null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilledButton(
                onPressed: _isSaving ? null : _submit,
                child: _isSaving
                    ? const SizedBox(
                        width: 16.0,
                        height: 16.0,
                        child: CircularProgressIndicator(strokeWidth: 2.0),
                      )
                    : const Text('Save'),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoadingData) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return Center(child: Text(_loadError!));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[

          // Coffee bag
          const _SectionLabel('Coffee'),
          DropdownButtonFormField<CoffeeBag>(
            value: _selectedBag,
            decoration: const InputDecoration(
              labelText: 'Bag',
              border: OutlineInputBorder(),
            ),
            // null item lets the user clear the selection
            items: <DropdownMenuItem<CoffeeBag>>[
              const DropdownMenuItem<CoffeeBag>(
                value: null,
                child: Text('— none —'),
              ),
              ..._bags.map(
                (CoffeeBag b) => DropdownMenuItem<CoffeeBag>(
                  value: b,
                  child: Text(b.displayName),
                ),
              ),
            ],
            onChanged: (CoffeeBag? b) => setState(() => _selectedBag = b),
          ),
          const SizedBox(height: 16.0),

          // ── Equipment ──────────────────────────────────────────────────────
          const _SectionLabel('Equipment'),
          DropdownButtonFormField<Brewer>(
            value: _selectedBrewer,
            decoration: const InputDecoration(
              labelText: 'Brewer',
              border: OutlineInputBorder(),
            ),
            items: <DropdownMenuItem<Brewer>>[
              const DropdownMenuItem<Brewer>(
                value: null,
                child: Text('— none —'),
              ),
              ..._brewers.map(
                (Brewer b) => DropdownMenuItem<Brewer>(
                  value: b,
                  child: Text(b.toString()),
                ),
              ),
            ],
            onChanged: (Brewer? b) => setState(() => _selectedBrewer = b),
          ),
          const SizedBox(height: 12.0),
          DropdownButtonFormField<Grinder>(
            value: _selectedGrinder,
            decoration: const InputDecoration(
              labelText: 'Grinder',
              border: OutlineInputBorder(),
            ),
            items: <DropdownMenuItem<Grinder>>[
              const DropdownMenuItem<Grinder>(
                value: null,
                child: Text('— none —'),
              ),
              ..._grinders.map(
                (Grinder g) => DropdownMenuItem<Grinder>(
                  value: g,
                  child: Text(g.toString()),
                ),
              ),
            ],
            onChanged: (Grinder? g) => setState(() => _selectedGrinder = g),
          ),
          const SizedBox(height: 16.0),

          // Rating
          const _SectionLabel('Rating'),
          Wrap(
            spacing: 8.0,
            children: _ratingOptions.map((String r) {
              return ChoiceChip(
                label: Text(r),
                selected: _selectedRating == r,
                // Tapping the selected chip deselects it (toggles to null).
                onSelected: (_) => setState(() {
                  _selectedRating = _selectedRating == r ? null : r;
                }),
              );
            }).toList(),
          ),
          const SizedBox(height: 16.0),

          // Brew parameters
          const _SectionLabel('Parameters'),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _coffeeGramsController,
                  decoration: const InputDecoration(
                    labelText: 'Coffee (g)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: TextField(
                  controller: _waterGramsController,
                  decoration: const InputDecoration(
                    labelText: 'Water (g)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _waterTempController,
                  decoration: const InputDecoration(
                    labelText: 'Temp (°C)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: TextField(
                  controller: _brewTimeController,
                  decoration: const InputDecoration(
                    labelText: 'Time (MM:SS)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.datetime,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),

          // Notes
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 8.0),

          // TODO: Put grind setting outside advanced?
          // Advanced (expandable)
          TextButton.icon(
            onPressed: () => setState(() => _showAdvanced = !_showAdvanced),
            icon: Icon(
              _showAdvanced ? Icons.expand_less : Icons.expand_more,
            ),
            label: Text(_showAdvanced ? 'Hide advanced' : 'Show advanced'),
          ),

          if (_showAdvanced) ...<Widget>[
            const SizedBox(height: 8.0),
            TextField(
              controller: _grindSettingController,
              decoration: const InputDecoration(
                labelText: 'Grind setting',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12.0),
            TextField(
              controller: _filterPaperController,
              decoration: const InputDecoration(
                labelText: 'Filter paper',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12.0),
            TextField(
              controller: _reviewController,
              decoration: const InputDecoration(
                labelText: 'Review',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
          ],

          // Extra bottom padding so the last field isn't obscured by the nav bar.
          const SizedBox(height: 32.0),
        ],
      ),
    );
  }
}

// Small uppercase section header — used only inside this file.
class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}
