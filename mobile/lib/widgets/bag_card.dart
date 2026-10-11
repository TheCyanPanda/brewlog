import 'package:flutter/material.dart';
import '../models/brew.dart';
import '../models/coffee_bag.dart';
import '../services/insights.dart';
import '../state/app_data.dart';
import '../theme.dart';
import '../utils/format.dart';
import 'bag_photo.dart';
import 'common.dart';

class BagCard extends StatelessWidget {
  final CoffeeBag bag;
  final AppData data;
  final VoidCallback? onTap;

  const BagCard({super.key, required this.bag, required this.data, this.onTap});

  @override
  Widget build(BuildContext context) {
    final List<Brew> brews = data.brewsForBag(bag.id);
    final Brew? best = bestBrew(brews);
    final int? rest = bag.daysSinceRoast;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              BagPhoto(data: data, bag: bag),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(bag.originLabel, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      bag.roaster ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: BrewColors.muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (bag.favorite) const Icon(Icons.favorite_rounded, color: BrewColors.copper, size: 18),
              if (bag.rating != null) ...<Widget>[
                const SizedBox(width: 6),
                RatingBadge(rating: bag.rating, compact: true),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              if (bag.status == 'unopened') const Pill('Unopened', icon: Icons.lock_outline_rounded, color: BrewColors.sage),
              if (bag.process != null) Pill(bag.process!),
              if (bag.variety != null) Pill(bag.variety!),
              if (bag.roastLevel != null) Pill(bag.roastLevel!),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Text('${brews.length} brews', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              if (best != null) ...<Widget>[
                const Text('  ·  ', style: TextStyle(color: BrewColors.muted)),
                Flexible(
                  child: Text(
                    'Best ${best.grindSetting ?? ''} @ ${formatNum(best.waterTempC)}°',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: BrewColors.muted, fontSize: 13),
                  ),
                ),
              ],
              const Spacer(),
              if (rest != null)
                Text('$rest d off roast', style: const TextStyle(color: BrewColors.muted, fontSize: 12.5)),
            ],
          ),
        ],
      ),
    );
  }
}
