import 'package:flutter/material.dart';

import '../models/brew.dart';
import '../models/coffee_bag.dart';
import '../services/insights.dart';
import '../state/app_data.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/charts.dart';
import '../widgets/chip_scroller.dart';
import '../widgets/common.dart';
import 'coffee_year_screen.dart';

/// Charts and statistics over the user's own brews.
class InsightsScreen extends StatefulWidget {
  final AppData data;

  const InsightsScreen({super.key, required this.data});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  int? _bagId; // bag shown in the dial-in charts

  AppData get data => widget.data;

  // Bags with at least one brew, most recently brewed first
  List<CoffeeBag> _bagsWithBrews() {
    final List<CoffeeBag> out = <CoffeeBag>[];
    final Set<int> seen = <int>{};
    for (final Brew b in data.brews) {
      final CoffeeBag? bag = data.bag(b.coffeeBagId);
      if (bag != null && seen.add(bag.id)) out.add(bag);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: ListenableBuilder(
        listenable: data,
        builder: (BuildContext context, _) {
          if (data.brews.isEmpty) {
            return const EmptyState(
              icon: Icons.insights_rounded,
              title: 'No insights yet',
              message: 'Log a few brews and your stats and charts show up here.',
            );
          }
          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: <Widget>[
              _headline(),
              ..._dialIn(),
              ..._perMethod(),
              ..._rateHighest(),
              ..._tasteProfile(),
              _coffeeYearCard(context),
            ],
          );
        },
      ),
    );
  }

  // ---- Headline numbers ----

  Widget _headline() {
    final double? avg = averageScore(data.brews);
    return AppCard(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        children: <Widget>[
          Expanded(child: StatValue(value: '${brewsThisMonth(data.brews)}', label: 'this month', size: 22)),
          Expanded(
            child: StatValue(
              value: formatRatio(averageRatio(data.brews.where((Brew b) => !(data.brewer(b.brewerId)?.isEspresso ?? false)))),
              label: 'filter ratio',
              size: 22,
            ),
          ),
          Expanded(child: StatValue(value: '${brewStreak(data.brews)} d', label: 'streak', size: 22)),
          Expanded(
            child: StatValue(
              value: avg == null ? '–' : ratingLabel(ratingForScore(avg)),
              label: 'avg rating',
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  // ---- Dial-in for one bag ----

  List<Widget> _dialIn() {
    final List<CoffeeBag> bags = _bagsWithBrews();
    if (bags.isEmpty) return <Widget>[];
    final CoffeeBag bag = bags.firstWhere((CoffeeBag b) => b.id == _bagId, orElse: () => bags.first);
    final List<Brew> brews = data.brewsForBag(bag.id);
    final Brew? best = bestBrew(brews);
    final List<(double, double)> grind = ratingByGrind(brews);
    final List<(double, double)> rest = ratingByRestDays(bag, brews);

    return <Widget>[
      const SectionHeader('Dial-in per bag'),
      ChipScroller(
        height: 40,
        children: <Widget>[
          for (final CoffeeBag b in bags)
            ChoiceChip(
              label: Text(b.originCountry == null ? b.displayName : '${b.originCountry} · ${b.roaster ?? ''}'),
              selected: b.id == bag.id,
              showCheckmark: false,
              onSelected: (_) => setState(() => _bagId = b.id),
            ),
        ],
      ),
      const SizedBox(height: 6),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Grind vs rating', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              best?.grindSetting == null
                  ? bag.originLabel
                  : 'Best cup at ${best!.grindSetting} · ${best.brewHash ?? ''}',
              style: const TextStyle(color: BrewColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 14),
            ScatterChart(
              points: <ScatterPoint>[for (final (double x, double y) in grind) ScatterPoint(x, y)],
              xLabel: 'Grind setting',
              highlightX: best?.grindValue,
            ),
          ],
        ),
      ),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Rating vs days since roast', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              bag.roastDate == null ? 'No roast date on this bag' : 'Roasted ${formatDate(bag.roastDate!)}',
              style: const TextStyle(color: BrewColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 14),
            ScatterChart(
              points: <ScatterPoint>[for (final (double x, double y) in rest) ScatterPoint(x, y)],
              xLabel: 'Days since roast',
              formatX: (double v) => v.round().toString(),
            ),
          ],
        ),
      ),
    ];
  }

  // ---- Brews per method ----

  List<Widget> _perMethod() {
    final List<MapEntry<String, int>> byMethod =
        countBy(data.brews, (Brew b) => prettyBrewType(data.brewer(b.brewerId)?.brewType));
    if (byMethod.isEmpty) return <Widget>[];
    final int max = byMethod.first.value;
    return <Widget>[
      const SectionHeader('Brews per method'),
      AppCard(
        child: Column(
          children: <Widget>[
            for (int i = 0; i < byMethod.length; i++)
              BarRow(
                label: byMethod[i].key,
                fraction: byMethod[i].value / max,
                value: '${byMethod[i].value}',
                color: BrewColors.series[i % BrewColors.series.length],
              ),
          ],
        ),
      ),
    ];
  }

  // ---- Average rating by process / origin ----

  List<Widget> _rateHighest() {
    final List<MapEntry<String, double>> byProcess =
        averageScoreBy(data.brews, (Brew b) => data.bag(b.coffeeBagId)?.process);
    final List<MapEntry<String, double>> byOrigin =
        averageScoreBy(data.brews, (Brew b) => data.bag(b.coffeeBagId)?.originCountry);
    if (byProcess.isEmpty && byOrigin.isEmpty) return <Widget>[];

    Widget group(String title, List<MapEntry<String, double>> rows) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: const TextStyle(color: BrewColors.muted, fontSize: 12.5, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            for (final MapEntry<String, double> e in rows)
              BarRow(
                label: e.key,
                fraction: (e.value - 1) / 4,
                value: e.value.toStringAsFixed(1),
                color: ratingColor(ratingForScore(e.value)),
              ),
          ],
        );

    return <Widget>[
      const SectionHeader('What you rate highest'),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (byProcess.isNotEmpty) group('By process', byProcess),
            if (byProcess.isNotEmpty && byOrigin.isNotEmpty) const SizedBox(height: 14),
            if (byOrigin.isNotEmpty) group('By origin', byOrigin),
            const SizedBox(height: 8),
            const Text('Average rating, 1 = bad · 5 = excellent',
                style: TextStyle(color: BrewColors.muted, fontSize: 11.5)),
          ],
        ),
      ),
    ];
  }

  // ---- Taste profile ----

  List<Widget> _tasteProfile() {
    final TasteProfile p = tasteProfile(data.brews, data.bag);
    if (p.basedOn == 0) return <Widget>[];
    return <Widget>[
      const SectionHeader('Your taste profile'),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const IconTile(Icons.favorite_rounded, color: BrewColors.copper),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('You like', style: Theme.of(context).textTheme.titleMedium),
                      Text('Based on ${p.basedOn} top-rated brews',
                          style: const TextStyle(color: BrewColors.muted, fontSize: 12.5)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[for (final String t in p.tags) Chip(label: Text(t))],
            ),
          ],
        ),
      ),
    ];
  }

  // ---- Coffee year entry ----

  Widget _coffeeYearCard(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.fromLTRB(16, 18, 16, 6),
      gradient: const LinearGradient(
        colors: <Color>[Color(0xFF6B3F22), Color(0xFF3A2416)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      onTap: () => Navigator.push<void>(
        context,
        MaterialPageRoute<void>(builder: (_) => CoffeeYearScreen(data: data)),
      ),
      child: Row(
        children: <Widget>[
          const IconTile(Icons.auto_awesome_rounded, color: BrewColors.caramel, size: 44),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Your coffee year ${DateTime.now().year}', style: Theme.of(context).textTheme.titleMedium),
                const Text('Your year in brews, ready to share',
                    style: TextStyle(color: BrewColors.muted, fontSize: 13)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: BrewColors.muted),
        ],
      ),
    );
  }
}
