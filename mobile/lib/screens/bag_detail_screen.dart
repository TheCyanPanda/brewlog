import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../models/brew.dart';
import '../models/brew_draft.dart';
import '../models/coffee_bag.dart';
import '../models/equipment.dart';
import '../services/insights.dart';
import '../state/app_data.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../utils/url/open_url.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';
import 'brew_detail_screen.dart';
import 'log_brew_screen.dart';
import 'suggestions_screen.dart';

// Everything about one bag: your rating, best brew, how it changed with
// days off roast, all brews, and "Buy again".
class BagDetailScreen extends StatelessWidget {
  final AppData data;
  final CoffeeBag bag;

  const BagDetailScreen({super.key, required this.data, required this.bag});

  Future<void> _update(BuildContext context, CoffeeBag b, {String? status, bool? favorite, String? rating}) async {
    try {
      await data.updateBag(b, status: status, favorite: favorite, rating: rating);
    } on DioException catch (e) {
      if (context.mounted) showSnack(context, 'Could not update bag: ${e.message}');
    }
  }

  Future<void> _brew(BuildContext context, CoffeeBag b) async {
    final Brew? saved = await Navigator.push<Brew>(
      context,
      MaterialPageRoute<Brew>(
        fullscreenDialog: true,
        builder: (_) => LogBrewScreen(data: data, draft: BrewDraft(bagId: b.id)),
      ),
    );
    if (saved != null && context.mounted) showSnack(context, 'Saved ${saved.brewHash ?? 'brew'}');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: data,
      builder: (BuildContext context, _) {
        final CoffeeBag b = data.bag(bag.id) ?? bag;
        final List<Brew> brews = data.brewsForBag(b.id);
        final Brew? best = bestBrew(brews);
        final double? avg = averageScore(brews);
        final List<(double, double)> byRest = ratingByRestDays(b, brews);
        final List<(double, double)> byGrind = ratingByGrind(brews);
        final StartPoint? start = brews.isEmpty ? startPointFor(b, data.brews, data.bag, data.brewer) : null;

        return Scaffold(
          appBar: AppBar(
            title: Text(b.bagHash ?? 'Bag'),
            actions: <Widget>[
              IconButton(
                tooltip: b.favorite ? 'Remove favorite' : 'Favorite',
                icon: Icon(b.favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: b.favorite ? BrewColors.copper : null),
                onPressed: () => _update(context, b, favorite: !b.favorite),
              ),
              PopupMenuButton<String>(
                onSelected: (String s) => _update(context, b, status: s),
                itemBuilder: (_) => <PopupMenuEntry<String>>[
                  if (b.status != 'finished') const PopupMenuItem<String>(value: 'finished', child: Text('Mark as finished')),
                  if (b.status != 'opened') const PopupMenuItem<String>(value: 'opened', child: Text('Mark as opened')),
                ],
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: FilledButton.icon(
                onPressed: () => _brew(context, b),
                icon: const Icon(Icons.coffee_rounded),
                label: const Text('Brew this'),
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: <Widget>[
              // Hero
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(b.originLabel, style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text(
                      <String?>[b.roaster, b.roasterOriginCity].whereType<String>().join(' · '),
                      style: const TextStyle(color: BrewColors.muted, fontSize: 15),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: <Widget>[
                        Pill(
                          b.status == 'finished' ? 'Finished' : (b.status == 'unopened' ? 'Unopened' : 'In use'),
                          color: b.status == 'opened' ? BrewColors.sage : null,
                        ),
                        if (b.process != null) Pill(b.process!),
                        if (b.variety != null) Pill(b.variety!),
                        if (b.roastLevel != null) Pill('${b.roastLevel} roast'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Numbers
              AppCard(
                child: Row(
                  children: <Widget>[
                    Expanded(child: StatValue(value: '${brews.length}', label: 'brews', size: 24)),
                    Expanded(
                      child: StatValue(
                        value: avg == null ? '–' : ratingLabel(ratingForScore(avg)),
                        label: 'avg cup',
                        size: 24,
                      ),
                    ),
                    Expanded(
                      child: StatValue(
                        value: b.daysSinceRoast == null ? '–' : '${b.daysSinceRoast} d',
                        label: b.roastDate == null ? 'off roast' : 'roasted ${formatShortDate(b.roastDate!)}',
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),

              // Your overall rating of the bag
              const SectionHeader('Your rating of this bag'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: <Widget>[
                    for (final String r in kRatings.reversed)
                      Expanded(
                        child: _BagRatingButton(
                          rating: r,
                          selected: b.rating == r,
                          onTap: () => _update(context, b, rating: r),
                        ),
                      ),
                  ],
                ),
              ),

              if (b.tasteNotes != null && b.tasteNotes!.isNotEmpty) ...<Widget>[
                const SectionHeader('Roaster\'s taste notes'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[for (final String n in b.tasteNotes!) Chip(label: Text(n))],
                  ),
                ),
              ],

              // Best brew — the reason this app exists
              if (best != null) ...<Widget>[
                const SectionHeader('Best brew'),
                _BestBrewCard(
                  brew: best,
                  data: data,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(builder: (_) => BrewDetailScreen(data: data, brew: best)),
                  ),
                ),
              ],

              if (start != null) ...<Widget>[
                const SectionHeader('Start point'),
                AppCard(
                  child: Row(
                    children: <Widget>[
                      const IconTile(Icons.lightbulb_outline_rounded, color: BrewColors.sage),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Grind ${start.grindSetting ?? '–'} · ${formatNum(start.waterTempC)} °C',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                            ),
                            const SizedBox(height: 3),
                            Text(start.reason, style: const TextStyle(color: BrewColors.muted, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (byGrind.length >= 3) ...<Widget>[
                const SectionHeader('Dial-in: grind vs rating'),
                AppCard(
                  padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
                  child: ScatterChart(
                    points: <ScatterPoint>[for (final (double x, double y) in byGrind) ScatterPoint(x, y)],
                    xLabel: 'Grind setting',
                    highlightX: best?.grindValue,
                  ),
                ),
              ],

              if (byRest.length >= 3) ...<Widget>[
                const SectionHeader('How it changed off roast'),
                AppCard(
                  padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
                  child: ScatterChart(
                    points: <ScatterPoint>[for (final (double x, double y) in byRest) ScatterPoint(x, y)],
                    xLabel: 'Days since roast',
                    formatX: (double v) => v.toStringAsFixed(0),
                  ),
                ),
              ],

              // Actions
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: <Widget>[
                    if (brews.isNotEmpty)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(builder: (_) => SuggestionsScreen(data: data, bag: b)),
                          ),
                          icon: const Icon(Icons.tune_rounded, size: 18),
                          label: const Text('Improve'),
                        ),
                      ),
                    if (brews.isNotEmpty) const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => openUrl(b.buyUrl ??
                            'https://www.google.com/search?q=${Uri.encodeComponent('${b.roaster ?? ''} ${b.originLabel} coffee')}'),
                        icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                        label: const Text('Buy again'),
                      ),
                    ),
                  ],
                ),
              ),

              if (brews.isNotEmpty) ...<Widget>[
                const SectionHeader('All brews'),
                AppCard(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: <Widget>[
                      for (final Brew br in brews)
                        ListTile(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(builder: (_) => BrewDetailScreen(data: data, brew: br)),
                          ),
                          leading: Icon(ratingIcon(br.rating), color: ratingColor(br.rating)),
                          title: Text(
                            '${br.grindSetting ?? '–'} · ${formatNum(br.waterTempC)}° · ${formatRatio(br.ratio)}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text('${br.brewHash ?? ''} · ${formatRelative(br.brewDatetime)}'),
                          trailing: const Icon(Icons.chevron_right_rounded),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _BestBrewCard extends StatelessWidget {
  final Brew brew;
  final AppData data;
  final VoidCallback onTap;

  const _BestBrewCard({required this.brew, required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Brewer? brewer = data.brewer(brew.brewerId);
    final Grinder? grinder = data.grinder(brew.grinderId);
    return AppCard(
      onTap: onTap,
      gradient: LinearGradient(
        colors: <Color>[ratingColor(brew.rating).withValues(alpha: 0.22), BrewColors.card],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(brew.brewHash ?? 'Best brew', style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.4)),
              const Spacer(),
              RatingBadge(rating: brew.rating, compact: true),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(child: StatValue(value: brew.grindSetting ?? '–', label: grinder?.name ?? 'Grind')),
              Expanded(child: StatValue(value: '${formatNum(brew.waterTempC)}°', label: 'Temp')),
              Expanded(child: StatValue(value: formatRatio(brew.ratio), label: 'Ratio')),
              Expanded(child: StatValue(value: formatSeconds(brew.brewTimeSecs), label: prettyBrewType(brewer?.brewType))),
            ],
          ),
        ],
      ),
    );
  }
}

class _BagRatingButton extends StatelessWidget {
  final String rating;
  final bool selected;
  final VoidCallback onTap;

  const _BagRatingButton({required this.rating, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color c = ratingColor(rating);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: selected ? c.withValues(alpha: 0.2) : BrewColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: selected ? c : Colors.transparent, width: 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              children: <Widget>[
                Icon(ratingIcon(rating), color: selected ? c : BrewColors.muted, size: 24),
                const SizedBox(height: 4),
                Text(
                  ratingLabel(rating),
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: TextStyle(fontSize: 10.5, color: selected ? c : BrewColors.muted, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
