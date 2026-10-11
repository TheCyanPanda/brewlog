import 'package:flutter/material.dart';

import '../models/coffee_bag.dart';
import '../services/insights.dart';
import '../state/app_data.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';

/// "Your coffee year" — a yearly summary in the style of Spotify Wrapped.
class CoffeeYearScreen extends StatelessWidget {
  final AppData data;

  const CoffeeYearScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final int year = DateTime.now().year;
    final YearStats s = yearStats(year, data.brews, data.bag, data.brewer);
    final TasteProfile p = tasteProfile(
      data.brews.where((b) => b.brewDatetime.year == year).toList(),
      data.bag,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Coffee year')),
      body: s.brews == 0
          ? EmptyState(
              icon: Icons.auto_awesome_rounded,
              title: 'No brews in $year yet',
              message: 'Your coffee year fills up as you log brews.',
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: <Widget>[
                _hero(context, s),
                _bigNumbers(s),
                if (s.byMethod.isNotEmpty) ..._methods(s),
                ..._bags(context, s),
                if (p.tags.isNotEmpty) ..._youLike(p),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: FilledButton.icon(
                    onPressed: () => showSnack(context, 'Shared to your feed'),
                    icon: const Icon(Icons.ios_share_rounded),
                    label: const Text('Share to feed'),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _hero(BuildContext context, YearStats s) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFFE8B87A), Color(0xFFC0703F), Color(0xFF5A2E1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('YOUR COFFEE YEAR',
              style: TextStyle(color: Color(0xFF2B1D14), fontSize: 12, letterSpacing: 1.6, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('${s.year}',
              style: const TextStyle(
                  color: Color(0xFF2B1D14), fontSize: 64, height: 1.05, fontWeight: FontWeight.w900, letterSpacing: -2)),
          const SizedBox(height: 16),
          Text('${s.brews}',
              style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w800, height: 1)),
          const Text('cups brewed and logged',
              style: TextStyle(color: Color(0xFFFFF1E2), fontSize: 16, fontWeight: FontWeight.w600)),
          if (s.avgRatio != null) ...<Widget>[
            const SizedBox(height: 12),
            Text('Average ratio ${formatRatio(s.avgRatio)}',
                style: const TextStyle(color: Color(0xFFFFF1E2), fontSize: 13.5)),
          ],
        ],
      ),
    );
  }

  Widget _bigNumbers(YearStats s) {
    Widget tile(String value, String label, IconData icon, Color color) => Expanded(
          child: AppCard(
            margin: const EdgeInsets.all(5),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                IconTile(icon, color: color, size: 34),
                const SizedBox(height: 12),
                StatValue(value: value, label: label, size: 28),
              ],
            ),
          ),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 11),
      child: Column(
        children: <Widget>[
          Row(children: <Widget>[
            tile('${s.countries}', 'countries', Icons.public_rounded, BrewColors.sage),
            tile('${s.bags}', 'bags', Icons.inventory_2_rounded, BrewColors.caramel),
          ]),
          Row(children: <Widget>[
            tile('${s.washed}', 'washed cups', Icons.water_drop_rounded, BrewColors.series[2]),
            tile('${s.excellentCups}', 'excellent cups', Icons.sentiment_very_satisfied_rounded, ratingColor('excellent')),
          ]),
        ],
      ),
    );
  }

  List<Widget> _methods(YearStats s) {
    final int max = s.byMethod.first.value;
    return <Widget>[
      const SectionHeader('Per brew method'),
      AppCard(
        child: Column(
          children: <Widget>[
            for (int i = 0; i < s.byMethod.length; i++)
              BarRow(
                label: s.byMethod[i].key,
                fraction: s.byMethod[i].value / max,
                value: '${s.byMethod[i].value}',
                color: BrewColors.series[i % BrewColors.series.length],
              ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _bags(BuildContext context, YearStats s) {
    Widget row(String caption, CoffeeBag bag, String detail, IconData icon, Color color) => AppCard(
          child: Row(
            children: <Widget>[
              IconTile(icon, color: color, size: 44),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(caption.toUpperCase(),
                        style: const TextStyle(
                            fontSize: 11, letterSpacing: 1, color: BrewColors.muted, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(bag.originLabel, style: Theme.of(context).textTheme.titleMedium),
                    Text('${bag.roaster ?? ''} · $detail', style: const TextStyle(color: BrewColors.muted, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        );

    return <Widget>[
      if (s.mostBrewedBag != null || s.topRatedBag != null) const SectionHeader('Highlights'),
      if (s.mostBrewedBag != null)
        row('Most brewed', s.mostBrewedBag!, '${s.mostBrewedCount} brews', Icons.local_fire_department_rounded,
            BrewColors.copper),
      if (s.topRatedBag != null)
        row('Top rated', s.topRatedBag!, s.topRatedBag!.process ?? 'Your favourite', Icons.emoji_events_rounded,
            ratingColor('excellent')),
    ];
  }

  List<Widget> _youLike(TasteProfile p) => <Widget>[
        const SectionHeader('You like'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (int i = 0; i < p.tags.length; i++)
                Chip(
                  label: Text(p.tags[i]),
                  backgroundColor: BrewColors.series[i % BrewColors.series.length].withValues(alpha: 0.18),
                ),
            ],
          ),
        ),
      ];
}
