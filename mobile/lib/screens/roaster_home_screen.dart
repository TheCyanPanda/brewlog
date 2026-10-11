// Home for roaster accounts: their own app area, separate from the brew log.
// Tabs: Insights (how their coffees are brewed and rated at home),
// Coffees (what they have in the app) and Roastery (public page, plan, privacy).
// Numbers are example data until enough home brewers have logged their coffees.
import 'package:flutter/material.dart';

import '../demo/demo_data.dart';
import '../state/app_data.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import 'featured_roaster_screen.dart';
import 'login_screen.dart';
import 'roaster_portal_screen.dart';

class RoasterHomeScreen extends StatefulWidget {
  final AppData data;

  const RoasterHomeScreen({super.key, required this.data});

  @override
  State<RoasterHomeScreen> createState() => _RoasterHomeScreenState();
}

class _RoasterHomeScreenState extends State<RoasterHomeScreen> {
  int _tab = 0;

  Future<void> _logout() async {
    try {
      await widget.data.services.auth.logout();
    } catch (_) {
      // Logged out locally regardless of what the server says
    }
    widget.data.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute<void>(builder: (_) => LoginScreen(data: widget.data)),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: <Widget>[
          RoasterPortalScreen(data: widget.data, asRoaster: true),
          const _CoffeesTab(),
          _RoasteryTab(data: widget.data, onLogout: _logout),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (int i) => setState(() => _tab = i),
        destinations: const <NavigationDestination>[
          NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights_rounded), label: 'Insights'),
          NavigationDestination(icon: Icon(Icons.coffee_outlined), selectedIcon: Icon(Icons.coffee_rounded), label: 'Coffees'),
          NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront_rounded), label: 'Roastery'),
        ],
      ),
    );
  }
}

class _CoffeesTab extends StatelessWidget {
  const _CoffeesTab();

  @override
  Widget build(BuildContext context) {
    final FeaturedRoaster r = kFeaturedRoaster;
    return Scaffold(
      appBar: AppBar(title: const Text('Your coffees')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showSnack(context, 'Adding coffees is coming soon'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add coffee'),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: <Widget>[
          const DemoBanner(text: 'Example coffees and numbers for the demo roastery.'),
          for (int i = 0; i < r.coffees.length; i++) _CoffeeCard(coffee: r.coffees[i], insight: i < kCoffeeInsights.length ? kCoffeeInsights[i] : null),
        ],
      ),
    );
  }
}

class _CoffeeCard extends StatelessWidget {
  final RoasterCoffee coffee;
  final CoffeeInsight? insight;

  const _CoffeeCard({required this.coffee, required this.insight});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const IconTile(Icons.coffee_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(coffee.name, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text('${coffee.originCountry} · ${coffee.originRegion}',
                        style: const TextStyle(color: BrewColors.muted, fontSize: 13)),
                  ],
                ),
              ),
              if (insight != null) RatingBadge(rating: ratingForScore(insight!.avgScore), compact: true),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              Pill(coffee.process),
              Pill(coffee.variety),
              Pill('${coffee.roastLevel} roast'),
              for (final String n in coffee.notes) Pill(n, color: BrewColors.sage),
            ],
          ),
          if (insight != null) ...<Widget>[
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(child: StatValue(value: '${insight!.brews}', label: 'brews logged', size: 18)),
                Expanded(child: StatValue(value: '${insight!.users}', label: 'home brewers', size: 18)),
                Expanded(child: StatValue(value: '${insight!.bestTempC} °C', label: 'best temp', size: 18)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RoasteryTab extends StatelessWidget {
  final AppData data;
  final VoidCallback onLogout;

  const _RoasteryTab({required this.data, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final FeaturedRoaster r = kFeaturedRoaster;
    return Scaffold(
      appBar: AppBar(title: const Text('Roastery')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(
              children: <Widget>[
                Avatar(r.name, size: 64, color: BrewColors.caramel),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(r.name, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 2),
                      Text('${r.city} · Roaster account', style: const TextStyle(color: BrewColors.muted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AppCard(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => FeaturedRoasterScreen(data: data)),
            ),
            child: const Row(
              children: <Widget>[
                IconTile(Icons.visibility_outlined, color: BrewColors.sage),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Your public page', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      SizedBox(height: 3),
                      Text('What home brewers see: story, coffees and your recipe',
                          style: TextStyle(color: BrewColors.muted, fontSize: 13)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: BrewColors.muted),
              ],
            ),
          ),
          const SectionHeader('Your plan'),
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
          const SectionHeader('How we handle data'),
          AppCard(
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _PrivacyRow(Icons.groups_outlined, 'Aggregated and anonymised — never single brews or users'),
                _PrivacyRow(Icons.filter_9_plus_outlined, 'Shown only when at least 10 different users contributed'),
                _PrivacyRow(Icons.sell_outlined, 'Taste notes as counted tags, never quotes'),
                _PrivacyRow(Icons.how_to_reg_outlined, 'Only from users who opted in to share'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Log out'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _PrivacyRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 20, color: BrewColors.sage),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(height: 1.35))),
        ],
      ),
    );
  }
}
