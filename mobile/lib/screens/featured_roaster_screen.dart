// Featured roaster page (fictional partner "Nordlys Kafferosteri"): short
// story, their coffees and a recipe you can save. Paid placement is always
// marked as sponsored.
import 'package:flutter/material.dart';

import '../demo/demo_data.dart';
import '../state/app_data.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import 'community_screen.dart';

// "Sponsored" marker for paid content
class SponsoredChip extends StatelessWidget {
  const SponsoredChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: const Text(
        'SPONSORED',
        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1, color: Colors.white),
      ),
    );
  }
}

class FeaturedRoasterScreen extends StatefulWidget {
  final AppData data;

  const FeaturedRoasterScreen({super.key, required this.data});

  @override
  State<FeaturedRoasterScreen> createState() => _FeaturedRoasterScreenState();
}

class _FeaturedRoasterScreenState extends State<FeaturedRoasterScreen> {
  bool _saving = false;

  Future<void> _saveRecipe() async {
    const FeaturedRoaster r = kFeaturedRoaster;
    setState(() => _saving = true);
    await saveCommunityRecipe(
      context,
      widget.data,
      name: r.recipeName,
      brewType: 'v60',
      coffeeGrams: r.recipeDose,
      waterGrams: r.recipeWater,
      waterTempC: r.recipeTemp,
      brewTimeSecs: r.recipeTimeSecs,
      steps: r.recipeSteps,
      source: r.name,
    );
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    const FeaturedRoaster r = kFeaturedRoaster;
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            pinned: true,
            expandedHeight: 230,
            backgroundColor: BrewColors.background,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(start: 56, bottom: 14, end: 16),
              title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[Color(0xFF2E4A52), Color(0xFF3B2A40), Color(0xFF5A3F28)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: <Widget>[
                    Center(
                      child: Icon(Icons.auto_awesome_rounded, size: 72, color: Colors.white.withValues(alpha: 0.22)),
                    ),
                    const Positioned(top: 52, right: 16, child: SafeArea(child: SponsoredChip())),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const DemoBanner(text: 'Example partner page. Nordlys Kafferosteri is a fictional roaster.'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const Icon(Icons.place_rounded, size: 16, color: BrewColors.muted),
                          const SizedBox(width: 4),
                          Text('${r.city} · ${r.coffees.length} coffees in Brewlog',
                              style: const TextStyle(color: BrewColors.muted)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(r.tagline, style: theme.textTheme.titleMedium?.copyWith(height: 1.35)),
                      const SizedBox(height: 12),
                      for (final String para in r.article)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            para,
                            style: TextStyle(
                              height: 1.5,
                              fontSize: 14.5,
                              fontStyle: para.startsWith('“') ? FontStyle.italic : FontStyle.normal,
                              color: para.startsWith('“') ? BrewColors.caramel : BrewColors.text,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SectionHeader('Their coffees'),
                for (final RoasterCoffee c in r.coffees) _CoffeeCard(coffee: c),

                const SectionHeader("Roaster's recipe · V60"),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          IconTile(brewTypeIcon('v60')),
                          const SizedBox(width: 12),
                          Expanded(child: Text(r.recipeName, style: theme.textTheme.titleMedium)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: StatValue(
                              value: formatRatio(r.recipeWater / r.recipeDose),
                              label: '${formatNum(r.recipeDose)} g → ${formatNum(r.recipeWater)} g',
                            ),
                          ),
                          Expanded(child: StatValue(value: '${formatNum(r.recipeTemp)} °C', label: 'water')),
                          Expanded(child: StatValue(value: formatSeconds(r.recipeTimeSecs), label: 'brew time')),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Pill('Grind: ${r.recipeGrind}', icon: Icons.tune_rounded),
                      const SizedBox(height: 14),
                      for (int i = 0; i < r.recipeSteps.length; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: <Widget>[
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: BrewColors.caramel.withValues(alpha: 0.18),
                                child: Text('${i + 1}',
                                    style: const TextStyle(fontSize: 12, color: BrewColors.caramel, fontWeight: FontWeight.w700)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text(r.recipeSteps[i].name, style: const TextStyle(fontWeight: FontWeight.w600))),
                              Text(
                                '${formatNum(r.recipeSteps[i].waterMl)} g · ${formatSeconds(r.recipeSteps[i].durationSecs)}',
                                style: const TextStyle(color: BrewColors.muted),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _saving ? null : _saveRecipe,
                          icon: _saving
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.bookmark_add_rounded),
                          label: const Text('Save recipe'),
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 32),
                  child: Text(
                    'Featured placements are paid partnerships and always marked as sponsored. '
                    'Recommendations in Brewlog are never for sale.',
                    style: TextStyle(color: BrewColors.muted, fontSize: 12.5, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CoffeeCard extends StatelessWidget {
  final RoasterCoffee coffee;
  const _CoffeeCard({required this.coffee});

  @override
  Widget build(BuildContext context) {
    final RoasterCoffee c = coffee;
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
                    Text(c.name, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text('${c.originCountry} · ${c.originRegion}', style: const TextStyle(color: BrewColors.muted)),
                  ],
                ),
              ),
              Pill(c.roastLevel),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              Pill(c.process, icon: Icons.water_drop_outlined),
              Pill(c.variety, icon: Icons.eco_outlined),
              for (final String n in c.notes) Pill(n, color: BrewColors.caramel),
            ],
          ),
        ],
      ),
    );
  }
}
