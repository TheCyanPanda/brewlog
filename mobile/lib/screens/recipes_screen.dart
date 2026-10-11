import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../models/brew.dart';
import '../models/brew_draft.dart';
import '../models/recipe.dart';
import '../services/insights.dart';
import '../state/app_data.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../utils/string_utils.dart';
import '../widgets/common.dart';
import 'log_brew_screen.dart';

// "V60 · 15 g / 250 g · 93 °C"
String recipeSummary(Recipe r) => <String>[
      prettyBrewType(r.brewType),
      if (r.coffeeGrams != null && r.waterGrams != null) '${formatNum(r.coffeeGrams)} g / ${formatNum(r.waterGrams)} g',
      if (r.waterTempC != null) '${formatNum(r.waterTempC)} °C',
    ].join(' · ');

// "Bloom + 2 pours"
String? stepsSummary(List<BrewStep>? steps) {
  if (steps == null || steps.isEmpty) return null;
  final bool bloom = steps.first.name.toLowerCase().contains('bloom');
  final int pours = steps.length - (bloom ? 1 : 0);
  final String p = '$pours ${pours == 1 ? 'pour' : 'pours'}';
  return bloom ? (pours == 0 ? 'Bloom' : 'Bloom + $p') : p;
}

/// Saved recipes plus community recipes to discover.
class RecipesScreen extends StatefulWidget {
  final AppData data;

  const RecipesScreen({super.key, required this.data});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _CommunityRecipe {
  final String name;
  final String author;
  final String brewType;
  final double coffeeGrams;
  final double waterGrams;
  final double waterTempC;
  final int brewTimeSecs;
  final String notes;
  final double rating;
  final int brews;
  final int saves;

  const _CommunityRecipe(this.name, this.author, this.brewType, this.coffeeGrams, this.waterGrams, this.waterTempC,
      this.brewTimeSecs, this.notes, this.rating, this.brews, this.saves);
}

// Example community recipes for the Discover section
const List<_CommunityRecipe> _community = <_CommunityRecipe>[
  _CommunityRecipe('4:6 method', 'Kaffevän', 'v60', 20, 300, 92, 210,
      'Five pours of 60 g: the first two set sweetness/acidity, the last three strength.', 4.6, 2140, 1240),
  _CommunityRecipe('Quick one-cup V60', 'Kaffevän', 'v60', 12, 200, 94, 150,
      'Bloom 30 s, then one continuous pour.', 4.8, 312, 640),
  _CommunityRecipe('Sweet Aeropress', 'Bryggare_92', 'aeropress', 15, 220, 85, 120,
      'Inverted, stir 10 s, steep 1:30, press slowly.', 4.7, 188, 410),
  _CommunityRecipe('Turbo espresso', 'Espressonörd', 'espresso', 18, 45, 94, 15,
      'Coarser grind, fast shot — bright and clean for light roasts.', 4.4, 96, 520),
  _CommunityRecipe('Big batch Chemex', 'Morgonfika', 'chemex', 40, 650, 95, 300,
      'For four cups. Bloom 45 s with 100 g.', 4.3, 74, 230),
];

class _RecipesScreenState extends State<RecipesScreen> {
  bool _topRated = false;
  final Set<String> _saving = <String>{};

  AppData get data => widget.data;

  List<Brew> _brewsFor(Recipe r) => data.brews.where((Brew b) => b.recipeId == r.id).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipes'),
        actions: <Widget>[
          IconButton(
            tooltip: 'New recipe',
            onPressed: () => _openNewRecipe(context),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: data,
        builder: (BuildContext context, _) {
          final List<_CommunityRecipe> discover = List<_CommunityRecipe>.of(_community)
            ..sort((_CommunityRecipe a, _CommunityRecipe b) =>
                _topRated ? b.rating.compareTo(a.rating) : b.saves.compareTo(a.saves));
          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: <Widget>[
              const SectionHeader('My recipes', padding: EdgeInsets.fromLTRB(20, 8, 12, 8)),
              if (data.recipes.isEmpty)
                const AppCard(
                  child: Text('No recipes yet. Save one below or create your own.',
                      style: TextStyle(color: BrewColors.muted)),
                ),
              for (final Recipe r in data.recipes) _myRecipeCard(context, r),
              AppCard(
                onTap: () => _openNewRecipe(context),
                color: BrewColors.surface,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(Icons.add_rounded, color: BrewColors.caramel),
                    SizedBox(width: 8),
                    Text('New recipe', style: TextStyle(color: BrewColors.caramel, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const SectionHeader('Discover'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SegmentedButton<bool>(
                  showSelectedIcon: false,
                  segments: const <ButtonSegment<bool>>[
                    ButtonSegment<bool>(value: false, label: Text('Popular'), icon: Icon(Icons.trending_up_rounded)),
                    ButtonSegment<bool>(value: true, label: Text('Top rated'), icon: Icon(Icons.star_rounded)),
                  ],
                  selected: <bool>{_topRated},
                  onSelectionChanged: (Set<bool> s) => setState(() => _topRated = s.first),
                ),
              ),
              const SizedBox(height: 8),
              for (final _CommunityRecipe c in discover) _communityCard(context, c),
            ],
          );
        },
      ),
    );
  }

  Widget _myRecipeCard(BuildContext context, Recipe r) {
    final List<Brew> brews = _brewsFor(r);
    final double? avg = averageScore(brews);
    final String? steps = stepsSummary(r.steps);
    return AppCard(
      onTap: () => _openDetails(context, r),
      child: Row(
        children: <Widget>[
          IconTile(brewTypeIcon(r.brewType), size: 46),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(child: Text(r.name, style: Theme.of(context).textTheme.titleMedium, overflow: TextOverflow.ellipsis)),
                    if (r.isDefault) ...<Widget>[
                      const SizedBox(width: 8),
                      const Pill('Default', color: BrewColors.caramel),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(recipeSummary(r), style: const TextStyle(color: BrewColors.muted, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: <Widget>[
                    if (steps != null) Pill(steps, icon: Icons.format_list_numbered_rounded),
                    Pill('${brews.length} brews', icon: Icons.coffee_rounded),
                    if (avg != null) RatingBadge(rating: ratingForScore(avg), compact: true),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: BrewColors.muted),
        ],
      ),
    );
  }

  Widget _communityCard(BuildContext context, _CommunityRecipe c) {
    final bool saved = data.recipes.any((Recipe r) => r.name == c.name && r.source == c.author);
    return AppCard(
      child: Row(
        children: <Widget>[
          Avatar(c.author, size: 44),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(c.name, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text('${c.author} · ${prettyBrewType(c.brewType)} · ${formatNum(c.coffeeGrams)} g / ${formatNum(c.waterGrams)} g',
                    style: const TextStyle(color: BrewColors.muted, fontSize: 13)),
                const SizedBox(height: 6),
                Row(
                  children: <Widget>[
                    const Icon(Icons.star_rounded, size: 15, color: BrewColors.caramel),
                    const SizedBox(width: 3),
                    Text(c.rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    Text('  ·  ${_thousands(c.brews)} brews  ·  ${_thousands(c.saves)} saves',
                        style: const TextStyle(color: BrewColors.muted, fontSize: 12.5)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          saved
              ? const Pill('Saved', icon: Icons.check_rounded, color: BrewColors.sage)
              : FilledButton.tonal(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 38)),
                  onPressed: _saving.contains(c.name) ? null : () => _saveCommunity(c),
                  child: const Text('Save'),
                ),
        ],
      ),
    );
  }

  static String _thousands(int v) {
    final String s = v.toString();
    return s.length <= 3 ? s : '${s.substring(0, s.length - 3)} ${s.substring(s.length - 3)}';
  }

  Future<void> _saveCommunity(_CommunityRecipe c) async {
    setState(() => _saving.add(c.name));
    try {
      final Recipe r = await data.services.recipes.createRecipe(
        name: c.name,
        brewType: c.brewType,
        coffeeGrams: c.coffeeGrams,
        waterGrams: c.waterGrams,
        waterTempC: c.waterTempC,
        brewTimeSecs: c.brewTimeSecs,
        notes: c.notes,
        source: c.author,
      );
      data.addRecipeLocal(r);
      if (mounted) showSnack(context, '“${c.name}” saved to your recipes');
    } on DioException catch (e) {
      if (mounted) showSnack(context, 'Failed: ${e.message}');
    } finally {
      if (mounted) setState(() => _saving.remove(c.name));
    }
  }

  // ---- Details sheet ----

  void _openDetails(BuildContext context, Recipe r) {
    final List<Brew> brews = _brewsFor(r);
    final double? avg = averageScore(brews);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheet) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  IconTile(brewTypeIcon(r.brewType), size: 48),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(r.name, style: Theme.of(sheet).textTheme.titleLarge),
                        Text(
                          <String>[prettyBrewType(r.brewType), if (r.source != null) 'from ${r.source}'].join(' · '),
                          style: const TextStyle(color: BrewColors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: <Widget>[
                  Expanded(child: StatValue(value: '${formatNum(r.coffeeGrams)} g', label: 'coffee')),
                  Expanded(child: StatValue(value: '${formatNum(r.waterGrams)} g', label: 'water')),
                  Expanded(child: StatValue(value: formatRatio(r.ratio), label: 'ratio')),
                  Expanded(child: StatValue(value: r.waterTempC == null ? '–' : '${formatNum(r.waterTempC)}°', label: 'temp')),
                ],
              ),
              if (r.brewTimeSecs != null) ...<Widget>[
                const SizedBox(height: 14),
                StatValue(value: formatSeconds(r.brewTimeSecs), label: 'brew time'),
              ],
              if (r.steps != null && r.steps!.isNotEmpty) ...<Widget>[
                const SizedBox(height: 18),
                const Text('STEPS', style: TextStyle(fontSize: 12, letterSpacing: 1.1, color: BrewColors.muted, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                for (int i = 0; i < r.steps!.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: <Widget>[
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: BrewColors.cardHigh,
                          child: Text('${i + 1}', style: const TextStyle(fontSize: 12, color: BrewColors.caramel)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(r.steps![i].name, style: const TextStyle(fontWeight: FontWeight.w600))),
                        Text(
                          <String>[
                            if (r.steps![i].waterMl != null) '${formatNum(r.steps![i].waterMl)} g',
                            if (r.steps![i].durationSecs != null) formatSeconds(r.steps![i].durationSecs),
                          ].join(' · '),
                          style: const TextStyle(color: BrewColors.muted),
                        ),
                      ],
                    ),
                  ),
              ],
              if (r.notes != null) ...<Widget>[
                const SizedBox(height: 14),
                Text(r.notes!, style: const TextStyle(color: BrewColors.muted)),
              ],
              const SizedBox(height: 14),
              Text(
                brews.isEmpty
                    ? 'Not brewed yet'
                    : '${brews.length} brews · average ${ratingLabel(ratingForScore(avg ?? 3)).toLowerCase()}',
                style: const TextStyle(color: BrewColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(sheet);
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => LogBrewScreen(
                        data: data,
                        draft: BrewDraft(
                          recipeId: r.id,
                          coffeeGrams: r.coffeeGrams,
                          waterGrams: r.waterGrams,
                          waterTempC: r.waterTempC,
                          brewTimeSecs: r.brewTimeSecs,
                        ),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Brew with this'),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: Theme.of(sheet).colorScheme.error),
                onPressed: () async {
                  Navigator.pop(sheet);
                  await _delete(r);
                },
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Delete recipe'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _delete(Recipe r) async {
    try {
      await data.services.recipes.deleteRecipe(r.id);
      data.removeRecipeLocal(r.id);
      if (mounted) showSnack(context, '“${r.name}” deleted');
    } on DioException catch (e) {
      if (mounted) showSnack(context, 'Failed: ${e.message}');
    }
  }

  void _openNewRecipe(BuildContext context) {
    showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (_) => _NewRecipeSheet(data: data));
  }
}

// ---- New recipe ----

class _NewRecipeSheet extends StatefulWidget {
  final AppData data;
  const _NewRecipeSheet({required this.data});

  @override
  State<_NewRecipeSheet> createState() => _NewRecipeSheetState();
}

class _NewRecipeSheetState extends State<_NewRecipeSheet> {
  static const List<String> _types = <String>['v60', 'aeropress', 'espresso', 'chemex', 'kalita', 'french_press'];

  final TextEditingController _name = TextEditingController();
  final TextEditingController _dose = TextEditingController(text: '15');
  final TextEditingController _water = TextEditingController(text: '250');
  final TextEditingController _temp = TextEditingController(text: '93');
  final TextEditingController _time = TextEditingController(text: '3:00');
  final TextEditingController _notes = TextEditingController();
  String _type = 'v60';
  bool _default = false;
  bool _busy = false;

  @override
  void dispose() {
    for (final TextEditingController c in <TextEditingController>[_name, _dose, _water, _temp, _time, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _num(TextEditingController c) => double.tryParse(c.text.trim().replaceAll(',', '.'));

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return showSnack(context, 'Give the recipe a name');
    setState(() => _busy = true);
    try {
      final Recipe r = await widget.data.services.recipes.createRecipe(
        name: _name.text.trim(),
        brewType: _type,
        coffeeGrams: _num(_dose),
        waterGrams: _num(_water),
        waterTempC: _num(_temp),
        brewTimeSecs: parseSeconds(_time.text),
        notes: blankToNull(_notes.text),
        isDefault: _default,
      );
      widget.data.addRecipeLocal(r);
      if (mounted) Navigator.pop(context);
    } on DioException catch (e) {
      if (mounted) showSnack(context, 'Failed: ${e.message}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _setType(String t) {
    setState(() => _type = t);
    // Sensible defaults when switching to/from espresso
    if (t == 'espresso') {
      _dose.text = '18';
      _water.text = '36';
      _time.text = '0:28';
    } else if (_water.text == '36') {
      _dose.text = '15';
      _water.text = '250';
      _time.text = '3:00';
    }
  }

  @override
  Widget build(BuildContext context) {
    final double? d = _num(_dose);
    final double? w = _num(_water);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('New recipe', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Name', hintText: 'e.g. Morning V60'),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final String t in _types)
                  ChoiceChip(
                    label: Text(prettyBrewType(t).replaceAll('_', ' ')),
                    avatar: Icon(brewTypeIcon(t), size: 16),
                    selected: _type == t,
                    showCheckmark: false,
                    onSelected: (_) => _setType(t),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(child: _numField(_dose, 'Coffee', 'g')),
                const SizedBox(width: 10),
                Expanded(child: _numField(_water, 'Water', 'g')),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(child: _numField(_temp, 'Temp', '°C')),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _time,
                    keyboardType: TextInputType.datetime,
                    decoration: const InputDecoration(labelText: 'Time (m:ss)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Ratio ${formatRatio(d != null && w != null && d > 0 ? w / d : null)}',
              style: const TextStyle(color: BrewColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(controller: _notes, maxLines: 2, decoration: const InputDecoration(labelText: 'Notes (optional)')),
            const SizedBox(height: 4),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _default,
              onChanged: (bool v) => setState(() => _default = v),
              title: const Text('Use as default'),
              subtitle: const Text('Pre-selected when you log a brew', style: TextStyle(color: BrewColors.muted)),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: _busy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save recipe'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _numField(TextEditingController c, String label, String suffix) => TextField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(labelText: label, suffixText: suffix),
      );
}
