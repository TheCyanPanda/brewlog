// Log a brew in a few taps, Strava-style.
//
// Everything is pre-filled from your last brew of the selected bag (or your
// default recipe / a start point for a new bag): pick the bag, tap a rating,
// Save. Grind, dose, water and temperature are one tap away on steppers;
// rarely used fields live under "More details".
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../models/brew.dart';
import '../models/brew_draft.dart';
import '../models/coffee_bag.dart';
import '../models/equipment.dart';
import '../models/recipe.dart';
import '../services/insights.dart';
import '../state/app_data.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/add_bag_sheet.dart';
import '../widgets/chip_scroller.dart';
import '../widgets/common.dart';

class LogBrewScreen extends StatefulWidget {
  final AppData data;
  final BrewDraft? draft;

  const LogBrewScreen({super.key, required this.data, this.draft});

  @override
  State<LogBrewScreen> createState() => _LogBrewScreenState();
}

class _LogBrewScreenState extends State<LogBrewScreen> {
  AppData get data => widget.data;

  int? _bagId;
  int? _brewerId;
  int? _grinderId;
  int? _recipeId;
  double? _grind;           // numeric grind setting (most grinders)
  double _dose = 15;
  double _water = 250;
  double _temp = 93;
  int? _timeSecs;
  String? _filterPaper;
  String? _rating;
  DateTime _when = DateTime.now();
  final Set<String> _tasted = <String>{};
  final TextEditingController _noteController = TextEditingController();
  String? _hint;            // "Start point: based on 9 good brews…"
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final BrewDraft? d = widget.draft;
    final List<CoffeeBag> active = data.activeBags;
    _bagId = d?.bagId ?? (active.isEmpty ? null : active.first.id);
    _applyDefaultsForBag(_bagId);

    if (d != null) {
      _brewerId = d.brewerId ?? _brewerId;
      _grinderId = d.grinderId ?? _grinderId;
      _recipeId = d.recipeId ?? _recipeId;
      if (d.recipeId != null && d.coffeeGrams == null) _applyRecipe(data.recipe(d.recipeId));
      _grind = double.tryParse(d.grindSetting ?? '') ?? _grind;
      _dose = d.coffeeGrams ?? _dose;
      _water = d.waterGrams ?? _water;
      _temp = d.waterTempC ?? _temp;
      _timeSecs = d.brewTimeSecs ?? _timeSecs;
      _filterPaper = d.filterPaper ?? _filterPaper;
      if (d.note != null) _hint = d.note;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  // Pre-fill from the last brew of this bag, else your last brew + default recipe,
  // and for a brand-new bag a start point learned from similar coffees.
  void _applyDefaultsForBag(int? bagId) {
    final Brew? lastOfBag = bagId == null ? null : data.lastBrewForBag(bagId);
    final Brew? base = lastOfBag ?? data.lastBrew;
    _hint = null;

    if (base != null) {
      _brewerId = base.brewerId;
      _grinderId = base.grinderId;
      _recipeId = base.recipeId;
      _grind = base.grindValue;
      _dose = base.coffeeGrams ?? _dose;
      _water = base.waterGrams ?? _water;
      _temp = base.waterTempC ?? _temp;
      _timeSecs = base.brewTimeSecs;
      _filterPaper = base.filterPaper;
    } else {
      _brewerId = data.brewers.isEmpty ? null : data.brewers.first.id;
      _grinderId = data.grinders.isEmpty ? null : data.grinders.first.id;
      _applyRecipe(data.defaultRecipe);
    }

    // New bag: suggest a start point from similar coffees you've rated well
    final CoffeeBag? bag = data.bag(bagId);
    if (bag != null && lastOfBag == null) {
      final StartPoint? sp = startPointFor(
        bag, data.brews, data.bag, data.brewer,
        espresso: data.brewer(_brewerId)?.isEspresso ?? false,
      );
      if (sp != null) {
        _grind = double.tryParse(sp.grindSetting ?? '') ?? _grind;
        _temp = sp.waterTempC ?? _temp;
        _hint = 'Start point for a new bag. ${sp.reason}.';
      }
    }
  }

  void _applyRecipe(Recipe? r) {
    if (r == null) return;
    _recipeId = r.id;
    _dose = r.coffeeGrams ?? _dose;
    _water = r.waterGrams ?? _water;
    _temp = r.waterTempC ?? _temp;
    _timeSecs = r.brewTimeSecs ?? _timeSecs;
    // Pick a matching brewer for the recipe's method, if you have one
    for (final Brewer b in data.brewers) {
      if (b.brewType == r.brewType) {
        _brewerId = b.id;
        break;
      }
    }
  }

  bool get _isEspresso => data.brewer(_brewerId)?.isEspresso ?? false;

  Future<void> _save() async {
    setState(() => _saving = true);
    final String note = _noteController.text.trim();
    try {
      final Brew brew = await data.addBrew(
        coffeeBagId: _bagId,
        brewerId: _brewerId,
        grinderId: _grinderId,
        recipeId: _recipeId,
        grindSetting: _grind == null ? null : formatNum(_grind),
        filterPaper: _filterPaper,
        coffeeGrams: _dose,
        waterGrams: _water,
        waterTempC: _temp,
        brewTimeSecs: _timeSecs,
        brewSteps: data.recipe(_recipeId)?.steps,
        brewDatetime: _when,
        rating: _rating,
        review: note.isEmpty ? null : note,
        notes: _tasted.isEmpty ? null : 'Tasted: ${_tasted.join(', ')}',
      );
      if (mounted) Navigator.pop(context, brew);
    } on DioException catch (e) {
      if (mounted) showSnack(context, 'Could not save brew: ${e.message}');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ---- Pickers ----

  Future<void> _addBag() async {
    final CoffeeBag? bag = await showModalBottomSheet<CoffeeBag>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddBagSheet(data: data),
    );
    if (bag != null) {
      setState(() {
        _bagId = bag.id;
        _applyDefaultsForBag(bag.id);
      });
    }
  }

  Future<void> _pick<T>({
    required String title,
    required List<T> items,
    required String Function(T) label,
    String Function(T)? subtitle,
    IconData Function(T)? icon,
    required bool Function(T) selected,
    required void Function(T?) onPicked,
    bool allowNone = false,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 12),
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(title, style: Theme.of(ctx).textTheme.titleMedium),
            ),
            if (allowNone)
              ListTile(
                leading: const Icon(Icons.block_rounded),
                title: const Text('None'),
                onTap: () {
                  Navigator.pop(ctx);
                  onPicked(null);
                },
              ),
            for (final T item in items)
              ListTile(
                leading: icon == null ? null : Icon(icon(item)),
                title: Text(label(item)),
                subtitle: subtitle == null ? null : Text(subtitle(item)),
                trailing: selected(item) ? const Icon(Icons.check_rounded, color: BrewColors.caramel) : null,
                onTap: () {
                  Navigator.pop(ctx);
                  onPicked(item);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _editTime() async {
    final TextEditingController c = TextEditingController(text: _timeSecs == null ? '' : formatSeconds(_timeSecs));
    final int? secs = await showDialog<int>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Brew time'),
        content: TextField(
          controller: c,
          autofocus: true,
          keyboardType: TextInputType.datetime,
          decoration: const InputDecoration(hintText: 'm:ss, e.g. 3:10'),
          onSubmitted: (String v) => Navigator.pop(ctx, parseSeconds(v)),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, parseSeconds(c.text)), child: const Text('Set')),
        ],
      ),
    );
    if (secs != null) setState(() => _timeSecs = secs);
  }

  Future<void> _editWhen() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _when,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return;
    final TimeOfDay? time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_when));
    setState(() => _when = DateTime(date.year, date.month, date.day, time?.hour ?? _when.hour, time?.minute ?? _when.minute));
  }

  Future<void> _editNumber(String title, double current, String unit, void Function(double) set) async {
    final TextEditingController c = TextEditingController(text: formatNum(current));
    final double? v = await showDialog<double>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: c,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(suffixText: unit),
          onSubmitted: (String s) => Navigator.pop(ctx, double.tryParse(s.replaceAll(',', '.'))),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, double.tryParse(c.text.replaceAll(',', '.'))),
            child: const Text('Set'),
          ),
        ],
      ),
    );
    if (v != null) setState(() => set(v));
  }

  // ---- UI ----

  @override
  Widget build(BuildContext context) {
    final CoffeeBag? bag = data.bag(_bagId);
    final Brewer? brewer = data.brewer(_brewerId);
    final Grinder? grinder = data.grinder(_grinderId);
    final Recipe? recipe = data.recipe(_recipeId);
    final double grindStep = _isEspresso ? 0.5 : 0.1;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
        title: const Text('Log brew'),
        actions: <Widget>[
          TextButton.icon(
            onPressed: _editWhen,
            icon: const Icon(Icons.schedule_rounded, size: 18),
            label: Text(DateTime.now().difference(_when).inMinutes.abs() < 2 ? 'Now' : formatRelative(_when)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: <Widget>[
          if (_hint != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: BrewColors.sage.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.lightbulb_outline_rounded, color: BrewColors.sage, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_hint!, style: const TextStyle(color: BrewColors.sage, fontSize: 13))),
                  ],
                ),
              ),
            ),

          // 1. Which coffee
          const SectionHeader('Coffee', padding: EdgeInsets.fromLTRB(20, 12, 12, 8)),
          ChipScroller(
            height: 92,
            spacing: 10,
            children: <Widget>[
              for (final CoffeeBag b in _bagChoices(bag))
                _BagChip(
                  bag: b,
                  selected: b.id == _bagId,
                  onTap: () => setState(() {
                    _bagId = b.id;
                    _applyDefaultsForBag(b.id);
                  }),
                ),
              _AddChip(onTap: _addBag),
            ],
          ),

          // 2. Setup: brewer · grinder · recipe (pre-selected, tap to change)
          const SectionHeader('Setup', padding: EdgeInsets.fromLTRB(20, 20, 12, 8)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _SetupTile(
                    icon: brewTypeIcon(brewer?.brewType),
                    label: 'Brewer',
                    value: brewer?.name ?? 'Choose',
                    onTap: () => _pick<Brewer>(
                      title: 'Brewer',
                      items: data.brewers,
                      label: (Brewer b) => b.name,
                      subtitle: (Brewer b) => prettyBrewType(b.brewType),
                      icon: (Brewer b) => brewTypeIcon(b.brewType),
                      selected: (Brewer b) => b.id == _brewerId,
                      onPicked: (Brewer? b) => setState(() => _brewerId = b?.id),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SetupTile(
                    icon: Icons.settings_input_component_rounded,
                    label: 'Grinder',
                    value: grinder?.name ?? 'None',
                    onTap: () => _pick<Grinder>(
                      title: 'Grinder',
                      items: data.grinders,
                      label: (Grinder g) => g.name,
                      selected: (Grinder g) => g.id == _grinderId,
                      allowNone: true, // pre-ground coffee
                      onPicked: (Grinder? g) => setState(() => _grinderId = g?.id),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SetupTile(
                    icon: Icons.menu_book_rounded,
                    label: 'Recipe',
                    value: recipe?.name ?? 'None',
                    onTap: () => _pick<Recipe>(
                      title: 'Recipe',
                      items: data.recipes,
                      label: (Recipe r) => r.name,
                      subtitle: (Recipe r) =>
                          '${prettyBrewType(r.brewType)} · ${formatNum(r.coffeeGrams)} g / ${formatNum(r.waterGrams)} g · ${formatNum(r.waterTempC)} °C',
                      icon: (Recipe r) => brewTypeIcon(r.brewType),
                      selected: (Recipe r) => r.id == _recipeId,
                      allowNone: true,
                      onPicked: (Recipe? r) => setState(() {
                        if (r == null) {
                          _recipeId = null;
                        } else {
                          _applyRecipe(r);
                        }
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. The numbers, one tap to nudge
          const SectionHeader('Brew', padding: EdgeInsets.fromLTRB(20, 20, 12, 8)),
          AppCard(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _Stepper(
                        label: 'Grind',
                        value: _grind == null ? '–' : formatNum(_grind),
                        onMinus: _grind == null ? null : () => setState(() => _grind = _round(_grind! - grindStep)),
                        onPlus: () => setState(() => _grind = _round((_grind ?? 0) + grindStep)),
                        onTap: () => _editNumber('Grind setting', _grind ?? 0, '', (double v) => _grind = v),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Stepper(
                        label: 'Temp',
                        value: '${formatNum(_temp)}°',
                        onMinus: () => setState(() => _temp -= 1),
                        onPlus: () => setState(() => _temp += 1),
                        onTap: () => _editNumber('Water temperature', _temp, '°C', (double v) => _temp = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _Stepper(
                        label: 'Coffee',
                        value: '${formatNum(_dose)} g',
                        onMinus: () => setState(() => _dose = _round(_dose - 0.5)),
                        onPlus: () => setState(() => _dose = _round(_dose + 0.5)),
                        onTap: () => _editNumber('Coffee', _dose, 'g', (double v) => _dose = v),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Stepper(
                        label: _isEspresso ? 'Yield' : 'Water',
                        value: '${formatNum(_water)} g',
                        onMinus: () => setState(() => _water -= _isEspresso ? 1 : 10),
                        onPlus: () => setState(() => _water += _isEspresso ? 1 : 10),
                        onTap: () => _editNumber(_isEspresso ? 'Yield' : 'Water', _water, 'g', (double v) => _water = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    StatValue(
                      value: formatRatio(_dose > 0 ? _water / _dose : null),
                      label: 'ratio',
                      align: CrossAxisAlignment.center,
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _editTime,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: StatValue(
                          value: _timeSecs == null ? 'Add' : formatSeconds(_timeSecs),
                          label: 'brew time',
                          align: CrossAxisAlignment.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 4. Rating — the one thing you always set
          const SectionHeader('How was it?', padding: EdgeInsets.fromLTRB(20, 20, 12, 8)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: <Widget>[
                for (final String r in kRatings.reversed)
                  Expanded(
                    child: _RatingButton(
                      rating: r,
                      selected: _rating == r,
                      onTap: () => setState(() => _rating = _rating == r ? null : r),
                    ),
                  ),
              ],
            ),
          ),

          // 5. Optional: taste + note
          const SectionHeader('Taste (optional)', padding: EdgeInsets.fromLTRB(20, 20, 12, 8)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final String t in <String>{...?bag?.tasteNotes, 'sweet', 'juicy', 'balanced', 'bitter', 'sour', 'thin'})
                  FilterChip(
                    label: Text(t),
                    selected: _tasted.contains(t),
                    onSelected: (bool on) => setState(() => on ? _tasted.add(t) : _tasted.remove(t)),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _noteController,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'Add a note — what will you change next time?'),
            ),
          ),

          // 6. Rarely needed
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: const Text('More details', style: TextStyle(fontWeight: FontWeight.w600)),
                childrenPadding: const EdgeInsets.fromLTRB(12, 10, 12, 8), // room for the floating label
                children: <Widget>[
                  TextFormField(
                    initialValue: _filterPaper,
                    decoration: const InputDecoration(labelText: 'Filter paper'),
                    onChanged: (String v) => _filterPaper = v.trim().isEmpty ? null : v.trim(),
                  ),
                  const SizedBox(height: 12),
                  if (recipe?.steps != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Steps: ${recipe!.steps!.map((BrewStep s) => '${s.name}${s.waterMl == null ? '' : ' ${formatNum(s.waterMl)} g'}').join(' → ')}',
                        style: const TextStyle(color: BrewColors.muted, fontSize: 13),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check_rounded),
            label: Text(_rating == null ? 'Save brew' : 'Save · ${ratingLabel(_rating)}'),
          ),
        ),
      ),
    );
  }

  // Active bags, plus the selected one if it is finished (e.g. from a draft)
  List<CoffeeBag> _bagChoices(CoffeeBag? selected) {
    final List<CoffeeBag> bags = data.activeBags;
    if (selected != null && !bags.any((CoffeeBag b) => b.id == selected.id)) return <CoffeeBag>[selected, ...bags];
    return bags;
  }

  static double _round(double v) => (v * 10).roundToDouble() / 10;
}

class _BagChip extends StatelessWidget {
  final CoffeeBag bag;
  final bool selected;
  final VoidCallback onTap;

  const _BagChip({required this.bag, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final int? rest = bag.daysSinceRoast;
    return Material(
      color: selected ? BrewColors.caramel.withValues(alpha: 0.16) : BrewColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: selected ? BrewColors.caramel : Colors.transparent, width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: 168,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                bag.originCountry ?? bag.roaster ?? 'Bag',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const SizedBox(height: 2),
              Text(
                bag.originRegion ?? bag.process ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: BrewColors.text, fontSize: 12.5),
              ),
              const SizedBox(height: 2),
              Text(
                '${bag.roaster ?? ''}${rest == null ? '' : ' · $rest d'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: BrewColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddChip extends StatelessWidget {
  final VoidCallback onTap;
  const _AddChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: BrewColors.outline, width: 1.2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: const SizedBox(
          width: 104,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.add_a_photo_outlined, color: BrewColors.caramel),
              SizedBox(height: 6),
              Text('New bag', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SetupTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _SetupTile({required this.icon, required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BrewColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(icon, size: 20, color: BrewColors.caramel),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(color: BrewColors.muted, fontSize: 11.5)),
              const SizedBox(height: 1),
              Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
            ],
          ),
        ),
      ),
    );
  }
}

// [−]  4.5  [+] with a caption; tap the value to type it
class _Stepper extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;
  final VoidCallback onTap;

  const _Stepper({required this.label, required this.value, required this.onMinus, required this.onPlus, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
      decoration: BoxDecoration(color: BrewColors.cardHigh.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(16)),
      child: Column(
      children: <Widget>[
        Text(label, style: const TextStyle(color: BrewColors.muted, fontSize: 12)),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _RoundIcon(icon: Icons.remove_rounded, onTap: onMinus),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    value,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700, letterSpacing: -0.4),
                  ),
                ),
              ),
            ),
            _RoundIcon(icon: Icons.add_rounded, onTap: onPlus),
          ],
        ),
      ],
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _RoundIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BrewColors.card,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(6), child: Icon(icon, size: 17, color: onTap == null ? BrewColors.outline : BrewColors.text)),
      ),
    );
  }
}

class _RatingButton extends StatelessWidget {
  final String rating;
  final bool selected;
  final VoidCallback onTap;

  const _RatingButton({required this.rating, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color c = ratingColor(rating);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: selected ? c.withValues(alpha: 0.2) : BrewColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: selected ? c : Colors.transparent, width: 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: <Widget>[
                AnimatedScale(
                  scale: selected ? 1.15 : 1,
                  duration: const Duration(milliseconds: 150),
                  child: Icon(ratingIcon(rating), color: selected ? c : BrewColors.muted, size: 28),
                ),
                const SizedBox(height: 6),
                Text(
                  ratingLabel(rating),
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? c : BrewColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
