import 'package:flutter/material.dart';

import '../models/brew.dart';
import '../models/coffee_bag.dart';
import '../services/insights.dart';
import '../state/app_data.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'coffee_year_screen.dart';
import 'equipment_screen.dart';
import 'insights_screen.dart';
import 'recipes_screen.dart';
import 'suggestions_screen.dart';

// Profile tab: totals, your taste, and everything that isn't daily logging.
class MeScreen extends StatelessWidget {
  final AppData data;
  final String? username;
  final VoidCallback onLogout;

  const MeScreen({super.key, required this.data, required this.onLogout, this.username});

  void _open(BuildContext context, Widget screen) =>
      Navigator.push(context, MaterialPageRoute<void>(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Me')),
      body: ListenableBuilder(
        listenable: data,
        builder: (BuildContext context, _) {
          final int countries = data.bags.map((CoffeeBag b) => b.originCountry).whereType<String>().toSet().length;
          final TasteProfile profile = tasteProfile(data.brews, data.bag);
          final int excellent = data.brews.where((Brew b) => b.rating == 'excellent').length;

          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Row(
                  children: <Widget>[
                    Avatar(username ?? 'Me', size: 64, color: BrewColors.caramel),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(username ?? 'Me', style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 2),
                          const Text('Home brewer · Brewlog', style: TextStyle(color: BrewColors.muted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              AppCard(
                child: Row(
                  children: <Widget>[
                    Expanded(child: StatValue(value: '${data.brews.length}', label: 'brews', size: 22)),
                    Expanded(child: StatValue(value: '${data.bags.length}', label: 'bags', size: 22)),
                    Expanded(child: StatValue(value: '$countries', label: 'countries', size: 22)),
                    Expanded(child: StatValue(value: '$excellent', label: 'excellent', size: 22)),
                  ],
                ),
              ),
              if (profile.tags.isNotEmpty) ...<Widget>[
                const SectionHeader('You like'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[for (final String t in profile.tags) Chip(label: Text(t))],
                  ),
                ),
              ],
              const SectionHeader('Your coffee'),
              _MenuCard(children: <Widget>[
                _MenuRow(
                  icon: Icons.auto_awesome_rounded,
                  color: BrewColors.caramel,
                  title: 'Your coffee year ${DateTime.now().year}',
                  subtitle: 'Your year in coffee, wrapped',
                  onTap: () => _open(context, CoffeeYearScreen(data: data)),
                ),
                _MenuRow(
                  icon: Icons.insights_rounded,
                  color: BrewColors.sage,
                  title: 'Insights',
                  subtitle: 'Charts, dial-in and taste profile',
                  onTap: () => _open(context, InsightsScreen(data: data)),
                ),
                _MenuRow(
                  icon: Icons.tune_rounded,
                  color: BrewColors.copper,
                  title: 'Suggestions',
                  subtitle: 'What to change for a better cup',
                  onTap: () => _open(context, SuggestionsScreen(data: data)),
                ),
              ]),
              const SectionHeader('Setup'),
              _MenuCard(children: <Widget>[
                _MenuRow(
                  icon: Icons.coffee_maker_outlined,
                  title: 'Equipment',
                  subtitle: '${data.grinders.length} grinders · ${data.brewers.length} brewers',
                  onTap: () => _open(context, EquipmentScreen(data: data)),
                ),
                _MenuRow(
                  icon: Icons.menu_book_rounded,
                  title: 'Recipes',
                  subtitle: '${data.recipes.length} saved',
                  onTap: () => _open(context, RecipesScreen(data: data)),
                ),
              ]),
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
          );
        },
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final List<Widget> children;
  const _MenuCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(children: children),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color = BrewColors.muted,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: IconTile(icon, color: color, size: 38),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(color: BrewColors.muted, fontSize: 12.5)),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}
