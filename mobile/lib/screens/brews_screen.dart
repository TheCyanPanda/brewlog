import 'package:flutter/material.dart';

import '../models/brew.dart';
import '../services/search.dart';
import '../state/app_data.dart';
import '../utils/format.dart';
import '../widgets/brew_card.dart';
import '../widgets/common.dart';
import '../widgets/search_filter_bar.dart';
import 'brew_detail_screen.dart';
import 'log_brew_screen.dart';

class BrewsScreen extends StatefulWidget {
  final AppData data;

  const BrewsScreen({super.key, required this.data});

  @override
  State<BrewsScreen> createState() => _BrewsScreenState();
}

class _BrewsScreenState extends State<BrewsScreen> {
  String? _rating; // null = all
  SearchFilters _filters = SearchFilters.none;

  Future<void> _logBrew() async {
    final Brew? brew = await Navigator.push<Brew>(
      context,
      MaterialPageRoute<Brew>(builder: (_) => LogBrewScreen(data: widget.data), fullscreenDialog: true),
    );
    if (brew != null && mounted) showSnack(context, 'Saved ${brew.brewHash ?? 'brew'}');
  }

  // "This week", "Earlier this month", "September 2026"
  String _section(DateTime d) {
    final DateTime now = DateTime.now();
    final int days = DateTime(now.year, now.month, now.day).difference(DateTime(d.year, d.month, d.day)).inDays;
    if (days < 7) return 'This week';
    if (d.year == now.year && d.month == now.month) return 'Earlier this month';
    const List<String> months = <String>[
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Brews')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _logBrew,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Log brew'),
      ),
      body: ListenableBuilder(
        listenable: widget.data,
        builder: (BuildContext context, _) {
          final AppData data = widget.data;
          final List<Brew> matching = data.brews
              .where((Brew b) => brewMatches(
                    b,
                    _filters,
                    bag: data.bag(b.coffeeBagId),
                    brewer: data.brewer(b.brewerId),
                    grinder: data.grinder(b.grinderId),
                  ))
              .toList();
          final List<Brew> brews = matching.where((Brew b) => _rating == null || b.rating == _rating).toList();

          final List<Widget> items = <Widget>[];
          String? current;
          for (final Brew b in brews) {
            final String s = _section(b.brewDatetime);
            if (s != current) {
              items.add(SectionHeader(s, padding: const EdgeInsets.fromLTRB(20, 18, 12, 6)));
              current = s;
            }
            items.add(BrewCard(
              brew: b,
              data: widget.data,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => BrewDetailScreen(data: widget.data, brew: b)),
              ),
            ));
          }

          return RefreshIndicator(
            onRefresh: widget.data.load,
            child: CustomScrollView(
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: SearchFilterBar(
                    data: data,
                    filters: _filters,
                    onChanged: (SearchFilters f) => setState(() => _filters = f),
                    hint: 'Search roaster, origin, notes…',
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 48,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text('All ${matching.length}'),
                            selected: _rating == null,
                            onSelected: (_) => setState(() => _rating = null),
                          ),
                        ),
                        for (final String r in kRatings.reversed)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              avatar: Icon(ratingIcon(r), size: 16, color: ratingColor(r)),
                              label: Text(ratingLabel(r)),
                              selected: _rating == r,
                              onSelected: (bool on) => setState(() => _rating = on ? r : null),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (brews.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.coffee_outlined,
                      title: data.brews.isEmpty
                          ? 'No brews yet'
                          : (_filters.isEmpty ? 'No ${ratingLabel(_rating).toLowerCase()} brews' : 'No brews match'),
                      message: data.brews.isEmpty
                          ? 'Log your first cup — it takes a few taps.'
                          : (_filters.isEmpty ? null : 'Try another search or clear the filters.'),
                      actionLabel: data.brews.isEmpty ? 'Log brew' : (_filters.isEmpty ? null : 'Clear search'),
                      onAction: data.brews.isEmpty
                          ? _logBrew
                          : () => setState(() {
                                _filters = SearchFilters.none;
                                _rating = null;
                              }),
                    ),
                  )
                else
                  SliverList.list(children: <Widget>[...items, const SizedBox(height: 96)]),
              ],
            ),
          );
        },
      ),
    );
  }
}
