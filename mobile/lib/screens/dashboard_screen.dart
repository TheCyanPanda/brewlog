import 'package:flutter/material.dart';

import '../models/brew.dart';
import '../models/brew_draft.dart';
import '../models/coffee_bag.dart';
import '../models/equipment.dart';
import '../services/insights.dart';
import '../state/app_data.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/brew_card.dart';
import '../widgets/common.dart';
import 'bag_detail_screen.dart';
import 'brew_detail_screen.dart';
import 'insights_screen.dart';
import 'log_brew_screen.dart';
import 'suggestions_screen.dart';

// Home tab: one-tap logging up top, then this month, tips and recent brews.
class DashboardScreen extends StatelessWidget {
  final AppData data;
  final String? username;
  final VoidCallback onSeeAllBrews;

  const DashboardScreen({super.key, required this.data, required this.onSeeAllBrews, this.username});

  Future<void> _log(BuildContext context, {BrewDraft? draft}) async {
    final Brew? saved = await Navigator.push<Brew>(
      context,
      MaterialPageRoute<Brew>(fullscreenDialog: true, builder: (_) => LogBrewScreen(data: data, draft: draft)),
    );
    if (saved != null && context.mounted) showSnack(context, 'Saved ${saved.brewHash ?? 'brew'}');
  }

  String _greeting() {
    final int h = DateTime.now().hour;
    if (h < 10) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: data,
          builder: (BuildContext context, _) {
            final List<CoffeeBag> active = data.activeBags;
            final CoffeeBag? current = active.where((CoffeeBag b) => b.status == 'opened').firstOrNull;
            final Brew? lastOfCurrent = current == null ? null : data.lastBrewForBag(current.id);
            final CoffeeBag? waiting = active.where((CoffeeBag b) => b.status == 'unopened').firstOrNull;
            final StartPoint? start = waiting == null ? null : startPointFor(waiting, data.brews, data.bag, data.brewer);
            final List<Brew> month = data.brews.where((Brew b) {
              final DateTime n = DateTime.now();
              return b.brewDatetime.year == n.year && b.brewDatetime.month == n.month;
            }).toList();
            final double? monthAvg = averageScore(month);
            final TasteProfile profile = tasteProfile(data.brews, data.bag);

            return RefreshIndicator(
              onRefresh: data.load,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(formatDate(DateTime.now()).toUpperCase(),
                                  style: const TextStyle(color: BrewColors.muted, fontSize: 12, letterSpacing: 1.1, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(_greeting(), style: Theme.of(context).textTheme.headlineMedium),
                            ],
                          ),
                        ),
                        Avatar(username ?? 'Me', size: 44, color: BrewColors.caramel),
                      ],
                    ),
                  ),

                  // Quick log: the main action of the app
                  _QuickLogCard(
                    data: data,
                    bag: current,
                    last: lastOfCurrent,
                    onLog: () => _log(context),
                    onSameAsLast: lastOfCurrent == null
                        ? null
                        : () => _log(
                              context,
                              draft: BrewDraft(
                                bagId: current!.id,
                                brewerId: lastOfCurrent.brewerId,
                                grinderId: lastOfCurrent.grinderId,
                                recipeId: lastOfCurrent.recipeId,
                                grindSetting: lastOfCurrent.grindSetting,
                                coffeeGrams: lastOfCurrent.coffeeGrams,
                                waterGrams: lastOfCurrent.waterGrams,
                                waterTempC: lastOfCurrent.waterTempC,
                                brewTimeSecs: lastOfCurrent.brewTimeSecs,
                                filterPaper: lastOfCurrent.filterPaper,
                              ),
                            ),
                  ),

                  // This month
                  const SectionHeader('This month'),
                  AppCard(
                    child: Row(
                      children: <Widget>[
                        Expanded(child: StatValue(value: '${month.length}', label: 'brews', size: 24)),
                        Expanded(child: StatValue(value: '${brewStreak(data.brews)} d', label: 'streak', size: 24)),
                        Expanded(
                          child: StatValue(
                            value: formatRatio(averageRatio(month.where((Brew b) => !(data.brewer(b.brewerId)?.isEspresso ?? false)))),
                            label: 'filter ratio',
                            size: 24,
                          ),
                        ),
                        Expanded(
                          child: StatValue(
                            value: monthAvg == null ? '–' : ratingLabel(ratingForScore(monthAvg)),
                            label: 'avg cup',
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // A new bag is waiting: give a start point
                  if (waiting != null && start != null)
                    AppCard(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(builder: (_) => BagDetailScreen(data: data, bag: waiting)),
                      ),
                      child: Row(
                        children: <Widget>[
                          const IconTile(Icons.fiber_new_rounded, color: BrewColors.sage, size: 44),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text('New bag: ${waiting.originLabel}',
                                    maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 3),
                                Text(
                                  'Start at grind ${start.grindSetting ?? '–'} · ${formatNum(start.waterTempC)} °C',
                                  style: const TextStyle(color: BrewColors.sage, fontWeight: FontWeight.w600, fontSize: 13.5),
                                ),
                                const SizedBox(height: 2),
                                Text(start.reason, style: const TextStyle(color: BrewColors.muted, fontSize: 12.5)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Suggestions + insights entry points
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: _EntryTile(
                            icon: Icons.tune_rounded,
                            title: 'Improve',
                            subtitle: 'More fruit, sweetness or body?',
                            color: BrewColors.caramel,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(builder: (_) => SuggestionsScreen(data: data, bag: current)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _EntryTile(
                            icon: Icons.insights_rounded,
                            title: 'Insights',
                            subtitle: profile.tags.isEmpty ? 'Your stats and charts' : 'You like ${profile.tags.take(2).join(', ').toLowerCase()}',
                            color: BrewColors.sage,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(builder: (_) => InsightsScreen(data: data)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SectionHeader('Recent brews', actionLabel: 'See all', onAction: onSeeAllBrews),
                  if (data.brews.isEmpty)
                    const EmptyState(icon: Icons.coffee_outlined, title: 'No brews yet', message: 'Tap "Log brew" to save your first cup.')
                  else
                    for (final Brew b in data.brews.take(3))
                      BrewCard(
                        brew: b,
                        data: data,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(builder: (_) => BrewDetailScreen(data: data, brew: b)),
                        ),
                      ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _QuickLogCard extends StatelessWidget {
  final AppData data;
  final CoffeeBag? bag;
  final Brew? last;
  final VoidCallback onLog;
  final VoidCallback? onSameAsLast;

  const _QuickLogCard({required this.data, required this.bag, required this.last, required this.onLog, required this.onSameAsLast});

  @override
  Widget build(BuildContext context) {
    final Brewer? brewer = data.brewer(last?.brewerId);
    return AppCard(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      padding: const EdgeInsets.all(18),
      gradient: const LinearGradient(
        colors: <Color>[Color(0xFF5A3F28), Color(0xFF33261C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            bag == null ? 'READY WHEN YOU ARE' : 'ON THE BAR',
            style: const TextStyle(fontSize: 11.5, letterSpacing: 1.2, fontWeight: FontWeight.w700, color: BrewColors.caramel),
          ),
          const SizedBox(height: 6),
          Text(
            bag?.originLabel ?? 'Log your first brew',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.3),
          ),
          if (bag != null) ...<Widget>[
            const SizedBox(height: 2),
            Text(
              '${bag!.roaster ?? ''}${bag!.daysSinceRoast == null ? '' : ' · ${bag!.daysSinceRoast} days off roast'}',
              style: const TextStyle(color: BrewColors.muted),
            ),
          ],
          if (last != null) ...<Widget>[
            const SizedBox(height: 14),
            Text(
              'Last: ${prettyBrewType(brewer?.brewType)} · grind ${last!.grindSetting ?? '–'} · ${formatNum(last!.waterTempC)}° · ${formatRatio(last!.ratio)}',
              style: const TextStyle(fontSize: 13.5),
            ),
            const SizedBox(height: 4),
            Row(
              children: <Widget>[
                Text(formatRelative(last!.brewDatetime), style: const TextStyle(color: BrewColors.muted, fontSize: 12.5)),
                const SizedBox(width: 8),
                if (last!.rating != null) RatingBadge(rating: last!.rating, compact: true),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.icon(
                  onPressed: onLog,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Log brew'),
                ),
              ),
              if (onSameAsLast != null) ...<Widget>[
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onSameAsLast,
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52)),
                    icon: const Icon(Icons.replay_rounded, size: 18),
                    label: const Text('Same as last'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _EntryTile({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BrewColors.card,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              IconTile(icon, color: color, size: 38),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5)),
              const SizedBox(height: 3),
              Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: BrewColors.muted, fontSize: 12.5)),
            ],
          ),
        ),
      ),
    );
  }
}
