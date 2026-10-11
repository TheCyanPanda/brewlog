import 'package:flutter/material.dart';

import '../models/brew.dart';
import '../models/coffee_bag.dart';
import '../services/search.dart';
import '../state/app_data.dart';
import '../widgets/add_bag_sheet.dart';
import '../widgets/bag_card.dart';
import '../widgets/common.dart';
import '../widgets/search_filter_bar.dart';
import 'bag_detail_screen.dart';

class BagsScreen extends StatefulWidget {
  final AppData data;

  const BagsScreen({super.key, required this.data});

  @override
  State<BagsScreen> createState() => _BagsScreenState();
}

enum _BagFilter { opened, finished, favorites, all }

class _BagsScreenState extends State<BagsScreen> {
  _BagFilter _filter = _BagFilter.opened;
  SearchFilters _search = SearchFilters.none;

  Future<void> _openAddBag() async {
    final CoffeeBag? bag = await showModalBottomSheet<CoffeeBag>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddBagSheet(data: widget.data),
    );
    if (bag != null && mounted) showSnack(context, 'Added ${bag.bagHash ?? 'bag'}');
  }

  bool _matches(CoffeeBag b, _BagFilter f) {
    switch (f) {
      case _BagFilter.opened: return b.status != 'finished';
      case _BagFilter.finished: return b.status == 'finished';
      case _BagFilter.favorites: return b.favorite;
      case _BagFilter.all: return true;
    }
  }

  String _label(_BagFilter f) {
    switch (f) {
      case _BagFilter.opened: return 'In use';
      case _BagFilter.finished: return 'Finished';
      case _BagFilter.favorites: return 'Favorites';
      case _BagFilter.all: return 'All';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My bags')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddBag,
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Add bag'),
      ),
      body: ListenableBuilder(
        listenable: widget.data,
        builder: (BuildContext context, _) {
          final AppData data = widget.data;

          // Grinders used per bag, for the "grinder used" filter
          final Map<int, Set<int>> grindersByBag = <int, Set<int>>{};
          for (final Brew br in data.brews) {
            if (br.coffeeBagId != null && br.grinderId != null) {
              (grindersByBag[br.coffeeBagId!] ??= <int>{}).add(br.grinderId!);
            }
          }
          bool searchMatch(CoffeeBag b) =>
              bagMatches(b, _search, grindersUsed: grindersByBag[b.id] ?? const <int>{});
          final List<CoffeeBag> found = data.bags.where(searchMatch).toList();

          // In use: most recently brewed first. Others: newest bag first.
          final List<CoffeeBag> bags = (_filter == _BagFilter.opened
                  ? data.activeBags
                  : data.bags.where((CoffeeBag b) => _matches(b, _filter)))
              .where(searchMatch)
              .toList();

          return RefreshIndicator(
            onRefresh: data.load,
            child: CustomScrollView(
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: SearchFilterBar(
                    data: data,
                    filters: _search,
                    onChanged: (SearchFilters f) => setState(() => _search = f),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        for (final _BagFilter f in _BagFilter.values)
                          ChoiceChip(
                            label: Text('${_label(f)} ${found.where((CoffeeBag b) => _matches(b, f)).length}'),
                            selected: _filter == f,
                            onSelected: (_) => setState(() => _filter = f),
                          ),
                      ],
                    ),
                  ),
                ),
                if (bags.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: _search.isEmpty ? 'No bags here' : 'No bags match',
                      message: _search.isEmpty
                          ? 'Snap a photo of a bag and we fill in the details.'
                          : (found.isEmpty ? 'Try another search or clear the filters.' : 'Matches are in another list — see the counts above.'),
                      actionLabel: _search.isEmpty ? 'Add bag' : 'Clear search',
                      onAction: _search.isEmpty ? _openAddBag : () => setState(() => _search = SearchFilters.none),
                    ),
                  )
                else
                  SliverList.list(
                    children: <Widget>[
                      const SizedBox(height: 4),
                      for (final CoffeeBag b in bags)
                        BagCard(
                          bag: b,
                          data: data,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(builder: (_) => BagDetailScreen(data: data, bag: b)),
                          ),
                        ),
                      const SizedBox(height: 96),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
