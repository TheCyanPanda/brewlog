import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../models/coffee_bag.dart';
import '../models/equipment.dart';
import '../services/app_services.dart';

// Sentinel value — signals "open add-new form" rather than a real selection.
const String _kAddNew = '__add_new__';

// File-level helper so all sheet widgets can use it without duplication.
String? _blankToNull(String s) => s.trim().isEmpty ? null : s.trim();

class AddBrewScreen extends StatefulWidget {
  final AppServices services;

  const AddBrewScreen({super.key, required this.services});

  @override
  State<AddBrewScreen> createState() => _AddBrewScreenState();
}

class _AddBrewScreenState extends State<AddBrewScreen> {
  // ── Dropdown data ──────────────────────────────────────────────────────────
  bool _isLoadingData = true;
  String? _loadError;

  List<CoffeeBag> _bags = <CoffeeBag>[];
  List<Brewer> _brewers = <Brewer>[];
  List<Grinder> _grinders = <Grinder>[];

  // ── Selected values ────────────────────────────────────────────────────────
  CoffeeBag? _selectedBag;
  Brewer? _selectedBrewer;
  Grinder? _selectedGrinder;
  String? _selectedRating;

  // GlobalKeys let us call didChange() to programmatically update the
  // FormField displayed value after auto-selecting a newly created item.
  final GlobalKey<FormFieldState<Object?>> _bagKey = GlobalKey();
  final GlobalKey<FormFieldState<Object?>> _brewerKey = GlobalKey();
  final GlobalKey<FormFieldState<Object?>> _grinderKey = GlobalKey();

  // ── Text controllers ───────────────────────────────────────────────────────
  final TextEditingController _coffeeGramsController = TextEditingController();
  final TextEditingController _waterGramsController = TextEditingController();
  final TextEditingController _waterTempController = TextEditingController();
  final TextEditingController _brewTimeController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // ── Advanced section ───────────────────────────────────────────────────────
  bool _showAdvanced = false;
  final TextEditingController _grindSettingController = TextEditingController();
  final TextEditingController _filterPaperController = TextEditingController();
  final TextEditingController _reviewController = TextEditingController();

  bool _isSaving = false;

  static const List<String> _ratingOptions = <String>[
    'excellent', 'good', 'ok', 'bad',
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
    return int.tryParse(trimmed);
  }

  // ── "Add new" sheet launchers ──────────────────────────────────────────────

  Future<void> _showAddBagSheet() async {
    final CoffeeBag? newBag = await showModalBottomSheet<CoffeeBag>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddBagSheet(services: widget.services),
    );
    if (newBag != null && mounted) {
      setState(() {
        _bags = <CoffeeBag>[..._bags, newBag];
        _selectedBag = newBag;
      });
      // Tell the FormField to display the new selection.
      _bagKey.currentState?.didChange(newBag);
    }
  }

  Future<void> _showAddBrewerSheet() async {
    final Brewer? newBrewer = await showModalBottomSheet<Brewer>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddBrewerSheet(services: widget.services),
    );
    if (newBrewer != null && mounted) {
      setState(() {
        _brewers = <Brewer>[..._brewers, newBrewer];
        _selectedBrewer = newBrewer;
      });
      _brewerKey.currentState?.didChange(newBrewer);
    }
  }

  Future<void> _showAddGrinderSheet() async {
    final Grinder? newGrinder = await showModalBottomSheet<Grinder>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddGrinderSheet(services: widget.services),
    );
    if (newGrinder != null && mounted) {
      setState(() {
        _grinders = <Grinder>[..._grinders, newGrinder];
        _selectedGrinder = newGrinder;
      });
      _grinderKey.currentState?.didChange(newGrinder);
    }
  }

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
    if (_isLoadingData) return const Center(child: CircularProgressIndicator());
    if (_loadError != null) return Center(child: Text(_loadError!));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[

          // ── Coffee bag ─────────────────────────────────────────────────────
          const _SectionLabel('Coffee'),
          DropdownButtonFormField<Object?>(
            key: _bagKey,
            initialValue: _selectedBag,
            decoration: const InputDecoration(
              labelText: 'Bag',
              border: OutlineInputBorder(),
            ),
            // selectedItemBuilder controls the closed-state display.
            // Must be index-matched 1:1 with items below.
            selectedItemBuilder: (BuildContext context) => <Widget>[
              const Text('none'),
              ..._bags.map(
                (CoffeeBag b) => Text(b.displayName, overflow: TextOverflow.ellipsis),
              ),
              const Text('+ Add new'),
            ],
            items: <DropdownMenuItem<Object?>>[
              const DropdownMenuItem<Object?>(value: null, child: Text('none')),
              ..._bags.map(
                (CoffeeBag b) => DropdownMenuItem<Object?>(
                  value: b,
                  child: Text(b.displayName),
                ),
              ),
              const DropdownMenuItem<Object?>(
                value: _kAddNew,
                child: Text('+ Add new', style: TextStyle(fontStyle: FontStyle.italic)),
              ),
            ],
            onChanged: (Object? b) {
              if (b == _kAddNew) {
                _showAddBagSheet();
              } else {
                setState(() => _selectedBag = b as CoffeeBag?);
              }
            },
          ),
          const SizedBox(height: 16.0),

          // ── Equipment ──────────────────────────────────────────────────────
          const _SectionLabel('Equipment'),
          DropdownButtonFormField<Object?>(
            key: _brewerKey,
            initialValue: _selectedBrewer,
            decoration: const InputDecoration(
              labelText: 'Brewer',
              border: OutlineInputBorder(),
            ),
            selectedItemBuilder: (BuildContext context) => <Widget>[
              const Text('none'),
              ..._brewers.map(
                (Brewer b) => Text(b.toString(), overflow: TextOverflow.ellipsis),
              ),
              const Text('+ Add new'),
            ],
            items: <DropdownMenuItem<Object?>>[
              const DropdownMenuItem<Object?>(value: null, child: Text('none')),
              ..._brewers.map(
                (Brewer b) => DropdownMenuItem<Object?>(
                  value: b,
                  child: Text(b.toString()),
                ),
              ),
              const DropdownMenuItem<Object?>(
                value: _kAddNew,
                child: Text('+ Add new', style: TextStyle(fontStyle: FontStyle.italic)),
              ),
            ],
            onChanged: (Object? b) {
              if (b == _kAddNew) {
                _showAddBrewerSheet();
              } else {
                setState(() => _selectedBrewer = b as Brewer?);
              }
            },
          ),
          const SizedBox(height: 12.0),
          DropdownButtonFormField<Object?>(
            key: _grinderKey,
            initialValue: _selectedGrinder,
            decoration: const InputDecoration(
              labelText: 'Grinder',
              border: OutlineInputBorder(),
            ),
            selectedItemBuilder: (BuildContext context) => <Widget>[
              const Text('none'),
              ..._grinders.map(
                (Grinder g) => Text(g.toString(), overflow: TextOverflow.ellipsis),
              ),
              const Text('+ Add new'),
            ],
            items: <DropdownMenuItem<Object?>>[
              const DropdownMenuItem<Object?>(value: null, child: Text('none')),
              ..._grinders.map(
                (Grinder g) => DropdownMenuItem<Object?>(
                  value: g,
                  child: Text(g.toString()),
                ),
              ),
              const DropdownMenuItem<Object?>(
                value: _kAddNew,
                child: Text('+ Add new', style: TextStyle(fontStyle: FontStyle.italic)),
              ),
            ],
            onChanged: (Object? g) {
              if (g == _kAddNew) {
                _showAddGrinderSheet();
              } else {
                setState(() => _selectedGrinder = g as Grinder?);
              }
            },
          ),
          const SizedBox(height: 16.0),

          // ── Rating ─────────────────────────────────────────────────────────
          const _SectionLabel('Rating'),
          Wrap(
            spacing: 8.0,
            children: _ratingOptions.map((String r) {
              return ChoiceChip(
                label: Text(r),
                selected: _selectedRating == r,
                onSelected: (_) => setState(() {
                  _selectedRating = _selectedRating == r ? null : r;
                }),
              );
            }).toList(),
          ),
          const SizedBox(height: 16.0),

          // ── Brew parameters ────────────────────────────────────────────────
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
                    labelText: 'Temp (C)',
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

          // ── Notes ──────────────────────────────────────────────────────────
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 8.0),

          // ── Advanced (expandable) ──────────────────────────────────────────
          TextButton.icon(
            onPressed: () => setState(() => _showAdvanced = !_showAdvanced),
            icon: Icon(_showAdvanced ? Icons.expand_less : Icons.expand_more),
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

          const SizedBox(height: 32.0),
        ],
      ),
    );
  }
}

// Small uppercase section header — private to this file.
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

// ── Bottom sheet: Add a new coffee bag ────────────────────────────────────────

class _AddBagSheet extends StatefulWidget {
  final AppServices services;
  const _AddBagSheet({required this.services});

  @override
  State<_AddBagSheet> createState() => _AddBagSheetState();
}

class _AddBagSheetState extends State<_AddBagSheet> {
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
        originCountry: _blankToNull(_countryController.text),
        originRegion: _blankToNull(_regionController.text),
        variety: _blankToNull(_varietyController.text),
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

// ── Bottom sheet: Add a new brewer ────────────────────────────────────────────

class _AddBrewerSheet extends StatefulWidget {
  final AppServices services;
  const _AddBrewerSheet({required this.services});

  @override
  State<_AddBrewerSheet> createState() => _AddBrewerSheetState();
}

class _AddBrewerSheetState extends State<_AddBrewerSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _brewTypeController = TextEditingController();
  String? _brewMethod;
  bool _isSaving = false;

  static const List<String> _brewMethods = <String>[
    'filter', 'espresso', 'aeropress', 'french_press', 'cold_brew', 'moka_pot', 'other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _brewTypeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final String name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name is required')),
      );
      return;
    }
    if (_brewMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Brew method is required')),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final Brewer brewer = await widget.services.equipment.createBrewer(
        name: name,
        brewMethod: _brewMethod!,
        brewType: _blankToNull(_brewTypeController.text),
      );
      if (mounted) Navigator.pop(context, brewer);
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
          Text('New Brewer', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16.0),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name *', border: OutlineInputBorder()),
            autofocus: true,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12.0),
          DropdownButtonFormField<String>(
            initialValue: _brewMethod,
            decoration: const InputDecoration(labelText: 'Brew method *', border: OutlineInputBorder()),
            items: _brewMethods
                .map((String m) => DropdownMenuItem<String>(value: m, child: Text(m)))
                .toList(),
            onChanged: (String? m) => setState(() => _brewMethod = m),
          ),
          const SizedBox(height: 12.0),
          TextField(
            controller: _brewTypeController,
            decoration: const InputDecoration(
              labelText: 'Type (e.g. V60, Chemex)',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 16.0),
          FilledButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(width: 16.0, height: 16.0, child: CircularProgressIndicator(strokeWidth: 2.0))
                : const Text('Add Brewer'),
          ),
        ],
      ),
    );
  }
}

// ── Bottom sheet: Add a new grinder ───────────────────────────────────────────

class _AddGrinderSheet extends StatefulWidget {
  final AppServices services;
  const _AddGrinderSheet({required this.services});

  @override
  State<_AddGrinderSheet> createState() => _AddGrinderSheetState();
}

class _AddGrinderSheetState extends State<_AddGrinderSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final String name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name is required')),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final Grinder grinder = await widget.services.equipment.createGrinder(
        name,
        notes: _blankToNull(_notesController.text),
      );
      if (mounted) Navigator.pop(context, grinder);
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
          Text('New Grinder', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16.0),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name *', border: OutlineInputBorder()),
            autofocus: true,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12.0),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()),
            maxLines: 2,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 16.0),
          FilledButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(width: 16.0, height: 16.0, child: CircularProgressIndicator(strokeWidth: 2.0))
                : const Text('Add Grinder'),
          ),
        ],
      ),
    );
  }
}
