// Community tab: Strava-style feed, map of roasters/cafés/shops and featured
// roasters. A preview built on example data (lib/demo/demo_data.dart); only
// "Save recipe" talks to the backend.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../demo/demo_data.dart';
import '../models/brew.dart';
import '../models/coffee_bag.dart';
import '../models/recipe.dart';
import '../state/app_data.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import '../widgets/sweden_map.dart';
import 'featured_roaster_screen.dart';
import 'roaster_portal_screen.dart';

/// Saves a recipe seen in the community (feed post, featured roaster) to the
/// user's own recipes, so it can be picked when logging a brew.
Future<void> saveCommunityRecipe(
  BuildContext context,
  AppData data, {
  required String name,
  required String brewType,
  required double coffeeGrams,
  required double waterGrams,
  required double waterTempC,
  required int brewTimeSecs,
  List<BrewStep>? steps,
  required String source,
}) async {
  try {
    final Recipe recipe = await data.services.recipes.createRecipe(
      name: name,
      brewType: brewType,
      coffeeGrams: coffeeGrams,
      waterGrams: waterGrams,
      waterTempC: waterTempC,
      brewTimeSecs: brewTimeSecs,
      steps: (steps == null || steps.isEmpty) ? null : steps,
      source: source,
    );
    data.addRecipeLocal(recipe);
    if (context.mounted) showSnack(context, '“$name” saved to your recipes');
  } on DioException {
    if (context.mounted) showSnack(context, 'Could not save the recipe. Is the server running?');
  }
}

class CommunityScreen extends StatelessWidget {
  final AppData data;

  const CommunityScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Community'),
          bottom: const TabBar(
            indicatorColor: BrewColors.caramel,
            indicatorSize: TabBarIndicatorSize.label,
            indicatorWeight: 3,
            labelColor: BrewColors.caramel,
            unselectedLabelColor: BrewColors.muted,
            dividerColor: Colors.transparent,
            labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
            tabs: <Tab>[Tab(text: 'Feed'), Tab(text: 'Map'), Tab(text: 'Roasters')],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            _FeedTab(data: data),
            const _MapTab(),
            _RoastersTab(data: data),
          ],
        ),
      ),
    );
  }
}

// ======================= Feed =======================

class _FeedTab extends StatefulWidget {
  final AppData data;
  const _FeedTab({required this.data});

  @override
  State<_FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends State<_FeedTab> with AutomaticKeepAliveClientMixin<_FeedTab> {
  bool _friendsOnly = false;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final List<FeedPost> posts = kFeedPosts.where((FeedPost p) => !_friendsOnly || p.isFriend).toList();

    return ListView(
      padding: const EdgeInsets.only(top: 12, bottom: 32),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SegmentedButton<bool>(
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: BrewColors.caramel.withValues(alpha: 0.18),
              selectedForegroundColor: BrewColors.caramel,
              side: const BorderSide(color: BrewColors.outline),
            ),
            segments: const <ButtonSegment<bool>>[
              ButtonSegment<bool>(value: true, label: Text('Friends'), icon: Icon(Icons.people_alt_rounded, size: 18)),
              ButtonSegment<bool>(value: false, label: Text('Everyone'), icon: Icon(Icons.public_rounded, size: 18)),
            ],
            selected: <bool>{_friendsOnly},
            onSelectionChanged: (Set<bool> s) => setState(() => _friendsOnly = s.first),
          ),
        ),
        const SizedBox(height: 8),
        const DemoBanner(text: 'Preview of the community feed with example posts'),
        ListenableBuilder(
          listenable: widget.data,
          builder: (BuildContext context, _) => _InspirationCard(data: widget.data),
        ),
        for (final FeedPost p in posts) _FeedPostCard(post: p, data: widget.data),
      ],
    );
  }
}

// "Others are brewing the same origin as your current bag"
class _InspirationCard extends StatelessWidget {
  final AppData data;
  const _InspirationCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final List<CoffeeBag> active = data.activeBags;
    if (active.isEmpty) return const SizedBox.shrink();
    final CoffeeBag bag = active.first;
    final String origin = bag.originCountry ?? bag.originLabel;

    return AppCard(
      gradient: LinearGradient(
        colors: <Color>[BrewColors.caramel.withValues(alpha: 0.20), BrewColors.card],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const IconTile(Icons.lightbulb_rounded),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Others brewing $origin', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  '23 people logged ${bag.originLabel} this week. Most used a V60 at about 93 °C '
                  'and rated it Good on average.',
                  style: const TextStyle(color: BrewColors.muted, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const List<List<Color>> _photoGradients = <List<Color>>[
  <Color>[Color(0xFF6B4226), Color(0xFF2B1A10)],
  <Color>[Color(0xFF4E3B5C), Color(0xFF1E1624)],
  <Color>[Color(0xFF8A5A2E), Color(0xFF33200F)],
  <Color>[Color(0xFF3F5A4A), Color(0xFF16201A)],
  <Color>[Color(0xFF5C3A2E), Color(0xFF241510)],
];

class _FeedPostCard extends StatefulWidget {
  final FeedPost post;
  final AppData data;
  const _FeedPostCard({required this.post, required this.data});

  @override
  State<_FeedPostCard> createState() => _FeedPostCardState();
}

class _FeedPostCardState extends State<_FeedPostCard> {
  bool _liked = false;
  bool _saving = false;

  Future<void> _saveRecipe() async {
    final FeedPost p = widget.post;
    setState(() => _saving = true);
    await saveCommunityRecipe(
      context,
      widget.data,
      name: '${p.recipeName} (${p.author})',
      brewType: p.brewType,
      coffeeGrams: p.coffeeGrams,
      waterGrams: p.waterGrams,
      waterTempC: p.waterTempC,
      brewTimeSecs: p.brewTimeSecs,
      steps: p.steps,
      source: p.author,
    );
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final FeedPost p = widget.post;
    final ThemeData theme = Theme.of(context);
    final List<Color> gradient = _photoGradients[p.photoHue % _photoGradients.length];

    return AppCard(
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Author
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
            child: Row(
              children: <Widget>[
                Avatar(p.author, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(p.author, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 2),
                      Row(
                        children: <Widget>[
                          Icon(brewTypeIcon(p.brewType), size: 13, color: BrewColors.muted),
                          const SizedBox(width: 4),
                          Text('${p.timeAgo} · ${prettyBrewType(p.brewType)}',
                              style: const TextStyle(color: BrewColors.muted, fontSize: 12.5)),
                        ],
                      ),
                    ],
                  ),
                ),
                if (p.isFriend) const Pill('Friend', icon: Icons.people_alt_rounded),
              ],
            ),
          ),

          // Photo / clip placeholder
          Container(
            height: 176,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
            child: Stack(
              children: <Widget>[
                Center(child: Icon(Icons.coffee_rounded, size: 64, color: Colors.white.withValues(alpha: 0.18))),
                if (p.videoLength != null)
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(Icons.play_arrow_rounded, size: 16, color: Colors.white),
                          const SizedBox(width: 2),
                          Text(p.videoLength!, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Coffee
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('${p.originCountry} · ${p.originRegion}', style: theme.textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(
                  '${p.roaster} · ${p.process} · ${p.daysOffRoast} days off roast',
                  style: const TextStyle(color: BrewColors.muted, fontSize: 13),
                ),
                const SizedBox(height: 14),

                // Big numbers, Strava-style
                Row(
                  children: <Widget>[
                    Expanded(child: StatValue(value: formatRatio(p.ratio), label: '${formatNum(p.coffeeGrams)} g → ${formatNum(p.waterGrams)} g')),
                    _vDivider(),
                    Expanded(child: StatValue(value: '${formatNum(p.waterTempC)} °C', label: 'water')),
                    _vDivider(),
                    Expanded(child: StatValue(value: formatSeconds(p.brewTimeSecs), label: 'brew time')),
                  ],
                ),
                const SizedBox(height: 14),

                // Equipment and recipe
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(Icons.tune_rounded, size: 15, color: BrewColors.muted),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        <String>[
                          '${p.grinder} @ ${p.grindSetting}',
                          ?p.filterPaper,
                          'Recipe: ${p.recipeName}',
                        ].join(' · '),
                        style: const TextStyle(color: BrewColors.muted, fontSize: 12.5, height: 1.35),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(p.note, style: const TextStyle(height: 1.4, fontSize: 14.5)),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Text(
                      p.brewId,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: BrewColors.muted, letterSpacing: 0.3),
                    ),
                    const Spacer(),
                    RatingBadge(rating: p.rating),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Divider(),

          // Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Row(
              children: <Widget>[
                TextButton.icon(
                  onPressed: () => setState(() => _liked = !_liked),
                  style: TextButton.styleFrom(foregroundColor: _liked ? BrewColors.caramel : BrewColors.muted),
                  icon: Icon(_liked ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 19),
                  label: Text('${p.likes + (_liked ? 1 : 0)}'),
                ),
                TextButton.icon(
                  onPressed: () => showSnack(context, 'Comments are coming soon'),
                  style: TextButton.styleFrom(foregroundColor: BrewColors.muted),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  label: Text('${p.comments}'),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _saving ? null : _saveRecipe,
                  icon: _saving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.bookmark_add_outlined, size: 19),
                  label: const Text('Save recipe'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _vDivider() => Container(
        width: 1,
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        color: BrewColors.outline.withValues(alpha: 0.6),
      );
}

// ======================= Map =======================

enum _PlaceSort { nearest, friends, everyone }

IconData _placeIcon(PlaceType t) {
  switch (t) {
    case PlaceType.roaster: return Icons.local_fire_department_rounded;
    case PlaceType.cafe: return Icons.local_cafe_rounded;
    case PlaceType.shop: return Icons.storefront_rounded;
  }
}

class _MapTab extends StatefulWidget {
  const _MapTab();

  @override
  State<_MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<_MapTab> with AutomaticKeepAliveClientMixin<_MapTab> {
  final Set<PlaceType> _types = PlaceType.values.toSet();
  _PlaceSort _sort = _PlaceSort.nearest;
  bool _nearMe = false;
  String? _selectedId;

  @override
  bool get wantKeepAlive => true;

  MapBounds get _bounds => _nearMe ? MapBounds.goteborg : MapBounds.southernSweden;

  bool _inBounds(Place p) =>
      p.lat >= _bounds.south && p.lat <= _bounds.north && p.lon >= _bounds.west && p.lon <= _bounds.east;

  List<Place> get _places {
    final List<Place> list = kPlaces.where((Place p) => _types.contains(p.type)).toList();
    int byRating(double? a, double? b) => (b ?? -1).compareTo(a ?? -1);
    switch (_sort) {
      case _PlaceSort.nearest:
        list.sort((Place a, Place b) => distanceFromUser(a).compareTo(distanceFromUser(b)));
        break;
      case _PlaceSort.friends:
        list.sort((Place a, Place b) => byRating(a.friendsRating, b.friendsRating));
        break;
      case _PlaceSort.everyone:
        list.sort((Place a, Place b) => byRating(a.everyoneRating, b.everyoneRating));
        break;
    }
    return list;
  }

  void _select(Place p) {
    setState(() {
      _selectedId = p.id;
      if (_nearMe && !_inBounds(p)) _nearMe = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final List<Place> places = _places;

    return ListView(
      padding: const EdgeInsets.only(top: 12, bottom: 32),
      children: <Widget>[
        // Type filters
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: <Widget>[
              for (final PlaceType t in PlaceType.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    avatar: Icon(_placeIcon(t), size: 16, color: placeColor(t)),
                    label: Text(t.plural),
                    selected: _types.contains(t),
                    showCheckmark: false,
                    onSelected: (bool on) => setState(() {
                      if (on) {
                        _types.add(t);
                      } else if (_types.length > 1) {
                        _types.remove(t);
                      }
                    }),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Map
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: <Widget>[
                SwedenMap(
                  places: places,
                  selectedId: _selectedId,
                  onSelect: _select,
                  bounds: _bounds,
                  height: 320,
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: _MapToggle(
                    nearMe: _nearMe,
                    onChanged: (bool v) => setState(() => _nearMe = v),
                  ),
                ),
                Positioned(
                  left: 12,
                  bottom: 10,
                  child: Row(
                    children: <Widget>[
                      for (final PlaceType t in PlaceType.values) ...<Widget>[
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: placeColor(t), shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        Text(t.plural, style: const TextStyle(fontSize: 10.5, color: BrewColors.muted)),
                        const SizedBox(width: 10),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Sort
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              const Text('Sort', style: TextStyle(color: BrewColors.muted, fontSize: 13)),
              for (final (_PlaceSort s, String label) in const <(_PlaceSort, String)>[
                (_PlaceSort.nearest, 'Nearest'),
                (_PlaceSort.friends, "Friends' rating"),
                (_PlaceSort.everyone, "Everyone's rating"),
              ])
                ChoiceChip(
                  label: Text(label),
                  selected: _sort == s,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _sort = s),
                ),
            ],
          ),
        ),
        const DemoBanner(text: 'Cafés, shops and ratings are example data. Roasters are shown by name and city only.'),

        for (final Place p in places)
          _PlaceRow(place: p, selected: p.id == _selectedId, onTap: () => _select(p)),
      ],
    );
  }
}

class _MapToggle extends StatelessWidget {
  final bool nearMe;
  final ValueChanged<bool> onChanged;
  const _MapToggle({required this.nearMe, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget seg(String label, bool value) => GestureDetector(
          onTap: () => onChanged(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: nearMe == value ? BrewColors.caramel : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: nearMe == value ? const Color(0xFF2B1D14) : BrewColors.text,
              ),
            ),
          ),
        );

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[seg('Sweden', false), seg('Near me', true)]),
    );
  }
}

class _PlaceRow extends StatelessWidget {
  final Place place;
  final bool selected;
  final VoidCallback onTap;
  const _PlaceRow({required this.place, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Place p = place;
    return AppCard(
      onTap: onTap,
      color: selected ? BrewColors.cardHigh : null,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: <Widget>[
          IconTile(_placeIcon(p.type), color: placeColor(p.type), size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 2),
                Text(
                  '${p.type.label} · ${formatDistance(distanceFromUser(p))} · ${p.city}',
                  style: const TextStyle(color: BrewColors.muted, fontSize: 12.5),
                ),
                if (p.serves != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(p.serves!, style: const TextStyle(color: BrewColors.muted, fontSize: 12.5)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (p.everyoneRating != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                if (p.friendsRating != null) _ratingLine('Friends', p.friendsRating!, BrewColors.caramel),
                _ratingLine('All', p.everyoneRating!, BrewColors.text),
              ],
            )
          else
            const Text('No ratings yet', style: TextStyle(color: BrewColors.muted, fontSize: 11.5)),
        ],
      ),
    );
  }

  Widget _ratingLine(String label, double value, Color color) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(label, style: const TextStyle(fontSize: 11, color: BrewColors.muted)),
            const SizedBox(width: 6),
            Icon(Icons.star_rounded, size: 14, color: color),
            Text(value.toStringAsFixed(1),
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: color)),
          ],
        ),
      );
}

// ======================= Roasters =======================

class _RoastersTab extends StatelessWidget {
  final AppData data;
  const _RoastersTab({required this.data});

  @override
  Widget build(BuildContext context) {
    const FeaturedRoaster r = kFeaturedRoaster;
    final List<Place> nearby = kPlaces.where((Place p) => p.type == PlaceType.roaster).toList()
      ..sort((Place a, Place b) => distanceFromUser(a).compareTo(distanceFromUser(b)));

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: <Widget>[
        const SectionHeader('Featured roaster', padding: EdgeInsets.fromLTRB(20, 16, 12, 8)),
        AppCard(
          padding: EdgeInsets.zero,
          onTap: () => Navigator.push<void>(
            context,
            MaterialPageRoute<void>(builder: (_) => FeaturedRoasterScreen(data: data)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                height: 150,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[Color(0xFF2E4A52), Color(0xFF3B2A40), Color(0xFF5A3F28)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: <Widget>[
                    Center(child: Icon(Icons.auto_awesome_rounded, size: 56, color: Colors.white.withValues(alpha: 0.25))),
                    const Positioned(top: 12, right: 12, child: SponsoredChip()),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(r.name, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 2),
                    Text('${r.city} · ${r.coffees.length} coffees in Brewlog',
                        style: const TextStyle(color: BrewColors.muted, fontSize: 13)),
                    const SizedBox(height: 10),
                    Text(r.tagline, style: const TextStyle(height: 1.4)),
                    const SizedBox(height: 12),
                    const Row(
                      children: <Widget>[
                        Text('Read the story', style: TextStyle(color: BrewColors.caramel, fontWeight: FontWeight.w700)),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, size: 18, color: BrewColors.caramel),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SectionHeader('Specialty roasters near you'),
        for (final Place p in nearby.take(6))
          AppCard(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: <Widget>[
                const IconTile(Icons.local_fire_department_rounded, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(p.city, style: const TextStyle(color: BrewColors.muted, fontSize: 12.5)),
                    ],
                  ),
                ),
                Text(formatDistance(distanceFromUser(p)), style: const TextStyle(color: BrewColors.muted)),
              ],
            ),
          ),

        const SectionHeader('For roasters'),
        AppCard(
          onTap: () => Navigator.push<void>(
            context,
            MaterialPageRoute<void>(builder: (_) => RoasterPortalScreen(data: data)),
          ),
          child: const Row(
            children: <Widget>[
              IconTile(Icons.insights_rounded, color: BrewColors.sage),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('See how your coffee tastes at home', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    SizedBox(height: 3),
                    Text('Preview the roaster portal: aggregated, anonymised insights per coffee.',
                        style: TextStyle(color: BrewColors.muted, fontSize: 13, height: 1.35)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: BrewColors.muted),
            ],
          ),
        ),
      ],
    );
  }
}
