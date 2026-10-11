import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../models/brew.dart';
import '../models/brew_draft.dart';
import '../models/coffee_bag.dart';
import '../models/equipment.dart';
import '../models/recipe.dart';
import '../state/app_data.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import 'bag_detail_screen.dart';
import 'log_brew_screen.dart';
import 'suggestions_screen.dart';

class BrewDetailScreen extends StatelessWidget {
  final AppData data;
  final Brew brew;

  const BrewDetailScreen({super.key, required this.data, required this.brew});

  Future<void> _brewAgain(BuildContext context) async {
    final Brew? saved = await Navigator.push<Brew>(
      context,
      MaterialPageRoute<Brew>(
        fullscreenDialog: true,
        builder: (_) => LogBrewScreen(
          data: data,
          draft: BrewDraft(
            bagId: brew.coffeeBagId,
            brewerId: brew.brewerId,
            grinderId: brew.grinderId,
            recipeId: brew.recipeId,
            grindSetting: brew.grindSetting,
            coffeeGrams: brew.coffeeGrams,
            waterGrams: brew.waterGrams,
            waterTempC: brew.waterTempC,
            brewTimeSecs: brew.brewTimeSecs,
            filterPaper: brew.filterPaper,
            note: 'Same settings as ${brew.brewHash ?? 'this brew'}.',
          ),
        ),
      ),
    );
    if (saved != null && context.mounted) showSnack(context, 'Saved ${saved.brewHash ?? 'brew'}');
  }

  Future<void> _delete(BuildContext context) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Delete brew?'),
        content: Text('${brew.brewHash ?? 'This brew'} will be removed.'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await data.deleteBrew(brew);
      if (context.mounted) Navigator.pop(context);
    } on DioException catch (e) {
      if (context.mounted) showSnack(context, 'Could not delete: ${e.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final CoffeeBag? bag = data.bag(brew.coffeeBagId);
    final Brewer? brewer = data.brewer(brew.brewerId);
    final Grinder? grinder = data.grinder(brew.grinderId);
    final Recipe? recipe = data.recipe(brew.recipeId);
    final int? rest = (bag?.roastDate == null) ? null : brew.brewDatetime.difference(bag!.roastDate!).inDays;

    return Scaffold(
      appBar: AppBar(
        title: Text(brew.brewHash ?? 'Brew'),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: (String v) {
              if (v == 'delete') _delete(context);
            },
            itemBuilder: (_) => const <PopupMenuEntry<String>>[
              PopupMenuItem<String>(value: 'delete', child: Text('Delete brew')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: <Widget>[
          // Hero: what and how it was
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${formatRelative(brew.brewDatetime)} · ${prettyBrewType(brewer?.brewType)}',
                  style: const TextStyle(color: BrewColors.muted),
                ),
                const SizedBox(height: 6),
                Text(bag?.originLabel ?? 'Unknown coffee', style: Theme.of(context).textTheme.headlineSmall),
                if (bag?.roaster != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    <String?>[bag!.roaster, bag.process, if (rest != null) '$rest days off roast']
                        .whereType<String>()
                        .join(' · '),
                    style: const TextStyle(color: BrewColors.muted),
                  ),
                ],
                const SizedBox(height: 14),
                RatingBadge(rating: brew.rating),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Key numbers
          AppCard(
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(child: StatValue(value: formatRatio(brew.ratio), label: 'Ratio', size: 24)),
                    Expanded(child: StatValue(value: '${formatNum(brew.coffeeGrams)} → ${formatNum(brew.waterGrams)} g', label: 'Coffee → water', size: 24)),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: <Widget>[
                    Expanded(child: StatValue(value: brew.waterTempC == null ? '–' : '${formatNum(brew.waterTempC)} °C', label: 'Water', size: 24)),
                    Expanded(child: StatValue(value: formatSeconds(brew.brewTimeSecs), label: 'Brew time', size: 24)),
                  ],
                ),
              ],
            ),
          ),

          // Gear
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: <Widget>[
                _Row(icon: brewTypeIcon(brewer?.brewType), label: 'Brewer', value: brewer?.name ?? '–'),
                _Row(
                  icon: Icons.settings_input_component_rounded,
                  label: 'Grinder',
                  value: grinder == null ? 'Pre-ground' : '${grinder.name} @ ${brew.grindSetting ?? '–'}',
                ),
                _Row(icon: Icons.menu_book_rounded, label: 'Recipe', value: recipe?.name ?? '–'),
                if (brew.filterPaper != null) _Row(icon: Icons.layers_outlined, label: 'Filter', value: brew.filterPaper!),
              ],
            ),
          ),

          if (brew.brewSteps != null && brew.brewSteps!.isNotEmpty) ...<Widget>[
            const SectionHeader('Steps'),
            AppCard(
              child: Column(
                children: <Widget>[
                  for (final BrewStep s in brew.brewSteps!)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: <Widget>[
                          const Icon(Icons.water_drop_outlined, size: 18, color: BrewColors.caramel),
                          const SizedBox(width: 10),
                          Expanded(child: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                          if (s.waterMl != null) Text('${formatNum(s.waterMl)} g', style: const TextStyle(color: BrewColors.muted)),
                          if (s.durationSecs != null) ...<Widget>[
                            const SizedBox(width: 12),
                            Text(formatSeconds(s.durationSecs), style: const TextStyle(color: BrewColors.muted)),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],

          if (brew.review != null || brew.notes != null) ...<Widget>[
            const SectionHeader('Notes'),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (brew.review != null) Text(brew.review!, style: const TextStyle(fontSize: 15, height: 1.4)),
                  if (brew.review != null && brew.notes != null) const SizedBox(height: 8),
                  if (brew.notes != null) Text(brew.notes!, style: const TextStyle(color: BrewColors.muted)),
                ],
              ),
            ),
          ],

          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                FilledButton.icon(
                  onPressed: () => _brewAgain(context),
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Brew again'),
                ),
                const SizedBox(height: 10),
                if (bag != null)
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(builder: (_) => SuggestionsScreen(data: data, bag: bag)),
                          ),
                          icon: const Icon(Icons.tune_rounded, size: 18),
                          label: const Text('Improve'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(builder: (_) => BagDetailScreen(data: data, bag: bag)),
                          ),
                          icon: const Icon(Icons.inventory_2_outlined, size: 18),
                          label: const Text('Bag'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _Row({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 20),
      title: Text(label, style: const TextStyle(color: BrewColors.muted, fontSize: 13.5)),
      trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
    );
  }
}
