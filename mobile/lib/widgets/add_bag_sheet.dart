import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/coffee_bag.dart';
import '../services/picker/image_picker.dart';
import '../services/scan_service.dart';
import '../state/app_data.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../utils/string_utils.dart';
import 'common.dart';

// Bottom sheet for a new bag: snap a photo of the label to fill everything in
// (read by Claude on the backend), or type it yourself. Returns the CoffeeBag.
class AddBagSheet extends StatefulWidget {
  final AppData data;
  const AddBagSheet({super.key, required this.data});

  @override
  State<AddBagSheet> createState() => _AddBagSheetState();
}

class _AddBagSheetState extends State<AddBagSheet> {
  final TextEditingController _roasterController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _regionController = TextEditingController();
  final TextEditingController _varietyController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String? _roastLevel;
  String? _process;
  DateTime? _roastDate;
  bool _opened = true;
  bool _isSaving = false;

  // Scan state
  Uint8List? _photo;
  bool _scanning = false;
  bool? _scanWasDemo;

  static const List<String> _roastLevels = <String>['Light', 'Medium-light', 'Medium', 'Medium-dark', 'Dark'];
  static const List<String> _processes = <String>['Washed', 'Natural', 'Honey', 'Anaerobic'];

  @override
  void dispose() {
    _roasterController.dispose();
    _countryController.dispose();
    _regionController.dispose();
    _varietyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final PickedImage? image;
    try {
      image = await pickImage();
    } on UnsupportedError catch (e) {
      if (mounted) showSnack(context, e.message ?? 'Not supported');
      return;
    }
    if (image == null || !mounted) return;

    setState(() {
      _photo = image!.bytes;
      _scanning = true;
      _scanWasDemo = null;
    });
    try {
      final ScanResult r = await widget.data.services.scan.scanBag(image);
      if (!mounted) return;
      setState(() {
        _fill(r.fields);
        _scanWasDemo = r.demo;
      });
    } on DioException catch (e) {
      if (mounted) showSnack(context, 'Could not read the label: ${e.message}');
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  // Put the scanned values into the form (keeps what you already typed if unknown)
  void _fill(Map<String, dynamic> f) {
    void set(TextEditingController c, Object? v) {
      if (v is String && v.trim().isNotEmpty) c.text = v.trim();
    }

    set(_roasterController, f['roaster']);
    set(_countryController, f['origin_country']);
    set(_regionController, f['origin_region']);
    set(_varietyController, f['variety']);
    final List<String> notes = (f['taste_notes'] as List<dynamic>? ?? <dynamic>[]).cast<String>();
    if (notes.isNotEmpty) _notesController.text = notes.join(', ');
    _roastLevel = _match(_roastLevels, f['roast_level'] as String?) ?? _roastLevel;
    _process = _match(_processes, f['process'] as String?) ?? (f['process'] as String? ?? _process);
    _roastDate = DateTime.tryParse(f['roast_date'] as String? ?? '') ?? _roastDate;
  }

  static String? _match(List<String> options, String? v) {
    if (v == null) return null;
    for (final String o in options) {
      if (o.toLowerCase() == v.toLowerCase()) return o;
    }
    return null;
  }

  Future<void> _pickRoastDate() async {
    final DateTime? d = await showDatePicker(
      context: context,
      initialDate: _roastDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => _roastDate = d);
  }

  Future<void> _save() async {
    final String roaster = _roasterController.text.trim();
    if (roaster.isEmpty) {
      showSnack(context, 'Roaster is required');
      return;
    }
    setState(() => _isSaving = true);
    try {
      final List<String> notes = _notesController.text
          .split(',')
          .map((String s) => s.trim().toLowerCase())
          .where((String s) => s.isNotEmpty)
          .toList();
      final CoffeeBag bag = await widget.data.services.bags.createBag(
        roaster: roaster,
        originCountry: blankToNull(_countryController.text),
        originRegion: blankToNull(_regionController.text),
        variety: blankToNull(_varietyController.text),
        roastLevel: _roastLevel,
        process: _process,
        tasteNotes: notes.isEmpty ? null : notes,
        roastDate: _roastDate,
        status: _opened ? 'opened' : 'unopened',
      );
      widget.data.addBagLocal(bag);
      if (mounted) Navigator.pop(context, bag);
    } on DioException catch (e) {
      if (mounted) showSnack(context, 'Failed: ${e.message}');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // viewInsets.bottom = keyboard height — keeps fields above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: <Widget>[
            Text('New bag', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _ScanCard(photo: _photo, scanning: _scanning, demo: _scanWasDemo, onScan: _scanning ? null : _scan),
            const SizedBox(height: 20),
            TextField(
              controller: _roasterController,
              decoration: const InputDecoration(labelText: 'Roaster *'),
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _countryController,
                    decoration: const InputDecoration(labelText: 'Origin'),
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _regionController,
                    decoration: const InputDecoration(labelText: 'Region'),
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _varietyController,
                    decoration: const InputDecoration(labelText: 'Variety'),
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _pickRoastDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Roast date'),
                      child: Text(_roastDate == null ? 'Pick' : formatDate(_roastDate!)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Process', style: TextStyle(color: BrewColors.muted, fontSize: 12.5)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final String p in _processes)
                  ChoiceChip(
                    label: Text(p),
                    selected: _process == p,
                    onSelected: (bool on) => setState(() => _process = on ? p : null),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            const Text('Roast', style: TextStyle(color: BrewColors.muted, fontSize: 12.5)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final String r in _roastLevels)
                  ChoiceChip(
                    label: Text(r),
                    selected: _roastLevel == r,
                    onSelected: (bool on) => setState(() => _roastLevel = on ? r : null),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Taste notes', hintText: 'blueberry, jasmine, bergamot'),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Opened'),
              subtitle: const Text('Turn off for a bag you are saving for later'),
              value: _opened,
              onChanged: (bool v) => setState(() => _opened = v),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Add bag'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanCard extends StatelessWidget {
  final Uint8List? photo;
  final bool scanning;
  final bool? demo;
  final VoidCallback? onScan;

  const _ScanCard({required this.photo, required this.scanning, required this.demo, required this.onScan});

  @override
  Widget build(BuildContext context) {
    final String title = scanning
        ? 'Reading the label…'
        : demo == null
            ? 'Scan the bag'
            : 'Label read — check the fields';
    final String subtitle = scanning
        ? 'Origin, process, roaster and roast date'
        : demo == null
            ? 'Take a photo and we fill everything in'
            : (demo! ? 'Example values: no AI key on the server' : 'Read by Claude · tap to scan again');

    return Material(
      color: BrewColors.caramel.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onScan,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: photo == null
                      ? Container(
                          color: BrewColors.caramel.withValues(alpha: 0.18),
                          child: const Icon(Icons.photo_camera_rounded, color: BrewColors.caramel),
                        )
                      : Stack(
                          fit: StackFit.expand,
                          children: <Widget>[
                            Image.memory(photo!, fit: BoxFit.cover),
                            if (scanning)
                              Container(
                                color: Colors.black45,
                                child: const Center(
                                  child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5)),
                                ),
                              ),
                          ],
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5)),
                    const SizedBox(height: 3),
                    Text(subtitle, style: const TextStyle(color: BrewColors.muted, fontSize: 12.5)),
                  ],
                ),
              ),
              if (demo != null && !scanning)
                Icon(
                  demo! ? Icons.info_outline_rounded : Icons.auto_awesome_rounded,
                  color: demo! ? BrewColors.muted : BrewColors.sage,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
