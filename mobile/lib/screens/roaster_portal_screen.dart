// What a partner roaster sees: aggregated, anonymised insights per coffee
// (how it is brewed and rated at home) plus the pricing tiers. Example data
// for the fictional roaster "Nordlys Kafferosteri".
import 'package:flutter/material.dart';

import '../demo/demo_data.dart';
import '../state/app_data.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/charts.dart';
import '../widgets/chip_scroller.dart';
import '../widgets/common.dart';

class RoasterPortalScreen extends StatefulWidget {
  final AppData data;
  // true when shown as the Insights tab of a logged-in roaster account
  // (plans live in the Roastery tab then); false = preview from the user app
  final bool asRoaster;

  const RoasterPortalScreen({super.key, required this.data, this.asRoaster = false});

  @override
  State<RoasterPortalScreen> createState() => _RoasterPortalScreenState();
}

class _RoasterPortalScreenState extends State<RoasterPortalScreen> {
  int _coffee = 0;

  @override
  Widget build(BuildContext context) {
    final CoffeeInsight c = kCoffeeInsights[_coffee];
    final ThemeData theme = Theme.of(context);
    final int maxNote = c.topNotes.first.value;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(widget.asRoaster ? 'Insights' : 'Roaster portal'),
            const Text('Nordlys Kafferosteri', style: TextStyle(fontSize: 13, color: BrewColors.muted, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: <Widget>[
          DemoBanner(
            text: widget.asRoaster
                ? 'Example numbers. Real insights appear once at least 10 different home brewers have logged your coffee.'
                : 'Preview of what a partner roaster sees. Fictional roaster, example numbers.',
          ),

          // Coffee picker
          ChipScroller(
            height: 44,
            children: <Widget>[
              for (int i = 0; i < kCoffeeInsights.length; i++)
                ChoiceChip(
                  label: Text(kCoffeeInsights[i].coffee),
                  selected: _coffee == i,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _coffee = i),
                ),
            ],
          ),

          const SectionHeader('Insights panel'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(c.coffee, style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text('${c.brews} brews from ${c.users} home brewers · last 90 days',
                    style: const TextStyle(color: BrewColors.muted, fontSize: 13)),
                const SizedBox(height: 18),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _Metric(
                        value: c.avgScore.toStringAsFixed(1),
                        label: 'avg rating',
                        sub: ratingLabel(ratingForScore(c.avgScore)),
                        color: ratingColor(ratingForScore(c.avgScore)),
                      ),
                    ),
                    Expanded(child: _Metric(value: '${c.bestTempC} °C', label: 'best rated at')),
                    Expanded(child: _Metric(value: c.bestRestDays, label: 'days off roast')),
                  ],
                ),
              ],
            ),
          ),

          const SectionHeader('Rating vs days since roast'),
          AppCard(
            padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ScatterChart(
                  points: <ScatterPoint>[for (final (double x, double y) in c.ratingByRest) ScatterPoint(x, y)],
                  xLabel: 'Days since roast',
                  height: 220,
                  formatX: (double v) => v.round().toString(),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(8, 4, 0, 4),
                  child: Text(
                    'Useful for rest-time advice on the bag and best-before dates.',
                    style: TextStyle(color: BrewColors.muted, fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ),

          const SectionHeader('How it is brewed'),
          AppCard(
            child: Column(
              children: <Widget>[
                for (int i = 0; i < c.methodShare.length; i++)
                  BarRow(
                    label: c.methodShare[i].key,
                    fraction: c.methodShare[i].value / 100,
                    value: '${c.methodShare[i].value} %',
                    color: BrewColors.series[i % BrewColors.series.length],
                  ),
              ],
            ),
          ),

          const SectionHeader('Most reported taste notes'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    for (final MapEntry<String, int> n in c.topNotes)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: BrewColors.caramel.withValues(alpha: 0.08 + 0.17 * n.value / maxNote),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(n.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(width: 8),
                            Text('${n.value}', style: const TextStyle(color: BrewColors.caramel, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text('Counted tags only — never quotes from users.',
                    style: TextStyle(color: BrewColors.muted, fontSize: 12.5)),
              ],
            ),
          ),

          // Privacy
          AppCard(
            margin: const EdgeInsets.fromLTRB(16, 20, 16, 6),
            color: BrewColors.sage.withValues(alpha: 0.10),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                IconTile(Icons.shield_rounded, color: BrewColors.sage),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Privacy by design', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      SizedBox(height: 4),
                      Text(
                        'Shown only when ≥ 10 different users contributed · aggregated & anonymised · '
                        'opt-in only · no usernames, locations or free text · fixed reports, no free queries.',
                        style: TextStyle(color: BrewColors.muted, fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (!widget.asRoaster) ...<Widget>[
          const SectionHeader('Plans for roasters'),
          for (final PriceTier t in kRoasterTiers) TierCard(tier: t),
          AppCard(
            color: BrewColors.caramel.withValues(alpha: 0.12),
            child: const Row(
              children: <Widget>[
                Icon(Icons.rocket_launch_rounded, color: BrewColors.caramel),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Free pilot for the first 10–20 roasters — in exchange for feedback and a case to show.',
                    style: TextStyle(fontWeight: FontWeight.w600, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          ],
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String value;
  final String label;
  final String? sub;
  final Color? color;

  const _Metric({required this.value, required this.label, this.sub, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: BrewColors.muted)),
        if (sub != null) Text(sub!, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class TierCard extends StatelessWidget {
  final PriceTier tier;
  const TierCard({super.key, required this.tier});

  @override
  Widget build(BuildContext context) {
    final PriceTier t = tier;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: BrewColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: t.highlighted ? BrewColors.caramel : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Expanded(
                  child: Text(t.name.toUpperCase(),
                      style: const TextStyle(fontSize: 12, letterSpacing: 1.1, fontWeight: FontWeight.w700, color: BrewColors.muted)),
                ),
                if (t.highlighted) const Pill('Most popular', color: BrewColors.caramel),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: <Widget>[
                Text(t.price, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                if (t.unit != null) ...<Widget>[
                  const SizedBox(width: 6),
                  Text(t.unit!, style: const TextStyle(color: BrewColors.muted)),
                ],
              ],
            ),
            const SizedBox(height: 10),
            for (final String f in t.features)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.check_rounded, size: 17, color: BrewColors.sage),
                    const SizedBox(width: 8),
                    Expanded(child: Text(f, style: const TextStyle(fontSize: 13.5))),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
