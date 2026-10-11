import 'package:flutter/material.dart';

import '../models/coffee_bag.dart';
import '../state/app_data.dart';
import '../widgets/add_bag_sheet.dart';
import '../widgets/bag_card.dart';
import '../widgets/common.dart';
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
          // In use: most recently brewed first. Others: newest bag first.
          final List<CoffeeBag> bags = _filter == _BagFilter.opened
              ? data.activeBags
              : data.bags.where((CoffeeBag b) => _matches(b, _filter)).toList();

          return RefreshIndicator(
            onRefresh: data.load,
            child: CustomScrollView(
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 48,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      children: <Widget>[
                        for (final _BagFilter f in _BagFilter.values)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text('${_label(f)} ${data.bags.where((CoffeeBag b) => _matches(b, f)).length}'),
                              selected: _filter == f,
                              onSelected: (_) => setState(() => _filter = f),
                            ),
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
                      title: 'No bags here',
                      message: 'Snap a photo of a bag and we fill in the details.',
                      actionLabel: 'Add bag',
                      onAction: _openAddBag,
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
