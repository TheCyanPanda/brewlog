import 'package:flutter/material.dart';

import '../models/brew.dart';
import '../models/brew_draft.dart';
import '../models/coffee_bag.dart';
import '../services/insights.dart';
import '../services/suggestion_engine.dart';
import '../state/app_data.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import 'log_brew_screen.dart';

/// "I want more …" — pick a goal, get one or two concrete changes for the next brew.
class SuggestionsScreen extends StatefulWidget {
  final AppData data;
  final CoffeeBag? bag;

  const SuggestionsScreen({super.key, required this.data, this.bag});

  @override
  State<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends State<SuggestionsScreen> {
  int? _bagId;
  TasteGoal _goal = TasteGoal.fruitiness;

  AppData get data => widget.data;

  @override
  void initState() {
    super.initState();
    _bagId = widget.bag?.id;
  }

  List<CoffeeBag> _bagsWithBrews() =>
      data.activeBags.where((CoffeeBag b) => data.lastBrewForBag(b.id) != null).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Suggestions')),
      body: ListenableBuilder(
        listenable: data,
        builder: (BuildContext context, _) {
          final List<CoffeeBag> bags = _bagsWithBrews();
          final List<CoffeeBag> unopened = data.bags.where((CoffeeBag b) => b.status == 'unopened').toList();
          if (bags.isEmpty && unopened.isEmpty) {
            return const EmptyState(
              icon: Icons.tips_and_updates_rounded,
              title: 'Nothing to suggest yet',
              message: 'Log a brew of an open bag and come back for suggestions.',
            );
          }
          CoffeeBag? bag;
          for (final CoffeeBag b in bags) {
            if (b.id == _bagId) bag = b;
          }
          bag ??= (widget.bag != null && data.lastBrewForBag(widget.bag!.id) != null) ? widget.bag : null;
          bag ??= bags.isEmpty ? null : bags.first;

          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: <Widget>[
              if (bag != null) ..._improve(context, bags, bag),
              if (unopened.isNotEmpty) ..._startPoints(context, unopened),
            ],
          );
        },
      ),
    );
  }

  // ---- Improve an open bag ----

  List<Widget> _improve(BuildContext context, List<CoffeeBag> bags, CoffeeBag bag) {
    final Brew base = data.lastBrewForBag(bag.id)!;
    final bool espresso = data.brewer(base.brewerId)?.isEspresso ?? false;
    final Suggestion s = suggest(goal: _goal, base: base, history: data.brewsForBag(bag.id), espresso: espresso);

    return <Widget>[
      const SectionHeader('Coffee', padding: EdgeInsets.fromLTRB(20, 8, 12, 8)),
      SizedBox(
        height: 40,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: bags.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (BuildContext context, int i) => ChoiceChip(
            label: Text(bags[i].originLabel),
            selected: bags[i].id == bag.id,
            showCheckmark: false,
            onSelected: (_) => setState(() => _bagId = bags[i].id),
          ),
        ),
      ),
      const SectionHeader('I want more …'),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final TasteGoal g in TasteGoal.values)
              ChoiceChip(
                label: Text(g.label),
                avatar: Icon(_goalIcon(g), size: 18),
                selected: g == _goal,
                showCheckmark: false,
                onSelected: (_) => setState(() => _goal = g),
              ),
          ],
        ),
      ),
      const SectionHeader('Today'),
      _todayCard(context, bag, base),
      const SectionHeader('Try this'),
      _resultCard(context, s),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: FilledButton.icon(
          onPressed: s.tweaks.isEmpty ? null : () => _tryInNextBrew(context, bag, base, s),
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Try in next brew'),
        ),
      ),
    ];
  }

  Widget _todayCard(BuildContext context, CoffeeBag bag, Brew base) {
    final String? brewer = data.brewer(base.brewerId)?.name;
    final String? grinder = data.grinder(base.grinderId)?.name;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(bag.originLabel, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      <String?>[bag.process, bag.variety, bag.roastLevel].whereType<String>().join(' · '),
                      style: const TextStyle(color: BrewColors.muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              RatingBadge(rating: base.rating, compact: true),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(child: StatValue(value: base.waterTempC == null ? '–' : '${formatNum(base.waterTempC)} °C', label: 'temp')),
              Expanded(child: StatValue(value: base.grindSetting ?? '–', label: 'grind')),
              Expanded(child: StatValue(value: formatRatio(base.ratio), label: 'ratio')),
              Expanded(child: StatValue(value: base.brewTimeDisplay ?? formatSeconds(base.brewTimeSecs), label: 'time')),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            <String?>[
              brewer,
              if (grinder != null) '$grinder${base.grindSetting == null ? '' : ' @ ${base.grindSetting}'}',
              '${formatNum(base.coffeeGrams)} g → ${formatNum(base.waterGrams)} g',
              formatRelative(base.brewDatetime),
            ].whereType<String>().join(' · '),
            style: const TextStyle(color: BrewColors.muted, fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  Widget _resultCard(BuildContext context, Suggestion s) {
    if (s.tweaks.isEmpty) {
      return const AppCard(
        child: Text('Your latest brew is already right where your best cups were. Keep it as it is!',
            style: TextStyle(color: BrewColors.muted)),
      );
    }
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (int i = 0; i < s.tweaks.length; i++) ...<Widget>[
            if (i > 0) const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
            _tweakRow(s.tweaks[i]),
          ],
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              const Icon(Icons.insights_rounded, size: 15, color: BrewColors.sage),
              const SizedBox(width: 6),
              Expanded(child: Text(s.basis, style: const TextStyle(color: BrewColors.sage, fontSize: 12.5))),
            ],
          ),
          const SizedBox(height: 6),
          const Row(
            children: <Widget>[
              Icon(Icons.lightbulb_outline_rounded, size: 15, color: BrewColors.muted),
              SizedBox(width: 6),
              Expanded(
                child: Text('Change one variable at a time and rate the result.',
                    style: TextStyle(color: BrewColors.muted, fontSize: 12.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tweakRow(Tweak t) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        IconTile(_fieldIcon(t.field), color: BrewColors.caramel),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(t.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 3),
              Text.rich(
                TextSpan(
                  children: <InlineSpan>[
                    TextSpan(text: '${t.fieldLabel}  '),
                    TextSpan(text: '${formatNum(t.from)}${t.unit}', style: const TextStyle(color: BrewColors.muted)),
                    const TextSpan(text: '  →  ', style: TextStyle(color: BrewColors.muted)),
                    TextSpan(
                      text: '${formatNum(t.to)}${t.unit}',
                      style: const TextStyle(color: BrewColors.caramel, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(t.why, style: const TextStyle(color: BrewColors.muted, fontSize: 12.5)),
            ],
          ),
        ),
      ],
    );
  }

  void _tryInNextBrew(BuildContext context, CoffeeBag bag, Brew base, Suggestion s) {
    final Map<TweakField, double> v = s.apply(base);
    final String note = 'Suggested: ${s.tweaks.map((Tweak t) => '${t.fieldLabel.toLowerCase()} '
        '${formatNum(t.from)} → ${formatNum(t.to)}${t.unit}').join(', ')}';
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => LogBrewScreen(
          data: data,
          draft: BrewDraft(
            bagId: bag.id,
            brewerId: base.brewerId,
            grinderId: base.grinderId,
            recipeId: base.recipeId,
            grindSetting: v.containsKey(TweakField.grind) ? formatNum(v[TweakField.grind]) : base.grindSetting,
            waterTempC: v[TweakField.temp] ?? base.waterTempC,
            coffeeGrams: v[TweakField.dose] ?? base.coffeeGrams,
            waterGrams: v[TweakField.water] ?? base.waterGrams,
            brewTimeSecs: base.brewTimeSecs,
            filterPaper: base.filterPaper,
            note: note,
          ),
        ),
      ),
    );
  }

  // ---- Start point for unopened bags ----

  List<Widget> _startPoints(BuildContext context, List<CoffeeBag> unopened) {
    final List<Widget> cards = <Widget>[];
    for (final CoffeeBag bag in unopened) {
      final StartPoint? sp = startPointFor(bag, data.brews, data.bag, data.brewer);
      cards.add(AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const IconTile(Icons.fiber_new_rounded, color: BrewColors.sage),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(bag.originLabel, style: Theme.of(context).textTheme.titleMedium),
                      Text(
                        <String?>[bag.roaster, bag.process].whereType<String>().join(' · '),
                        style: const TextStyle(color: BrewColors.muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (sp == null)
              const Text('Not enough similar brews yet for a start point.', style: TextStyle(color: BrewColors.muted))
            else ...<Widget>[
              Row(
                children: <Widget>[
                  Expanded(child: StatValue(value: sp.grindSetting ?? '–', label: 'start grind', size: 24)),
                  Expanded(
                    child: StatValue(
                      value: sp.waterTempC == null ? '–' : '${formatNum(sp.waterTempC)} °C',
                      label: 'start temp',
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(sp.reason, style: const TextStyle(color: BrewColors.sage, fontSize: 12.5)),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => LogBrewScreen(
                      data: data,
                      draft: BrewDraft(
                        bagId: bag.id,
                        grindSetting: sp.grindSetting,
                        waterTempC: sp.waterTempC,
                        note: 'Start point: ${sp.reason.toLowerCase()}',
                      ),
                    ),
                  ),
                ),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Brew with start point'),
              ),
            ],
          ],
        ),
      ));
    }
    return <Widget>[const SectionHeader('Start point for a new bag'), ...cards];
  }

  static IconData _goalIcon(TasteGoal g) {
    switch (g) {
      case TasteGoal.fruitiness: return Icons.local_florist_rounded;
      case TasteGoal.sweetness: return Icons.cake_rounded;
      case TasteGoal.body: return Icons.water_drop_rounded;
      case TasteGoal.lessBitter: return Icons.remove_circle_outline_rounded;
    }
  }

  static IconData _fieldIcon(TweakField f) {
    switch (f) {
      case TweakField.grind: return Icons.tune_rounded;
      case TweakField.temp: return Icons.thermostat_rounded;
      case TweakField.dose: return Icons.scale_rounded;
      case TweakField.water: return Icons.water_drop_outlined;
    }
  }
}
