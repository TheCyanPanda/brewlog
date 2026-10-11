import 'package:flutter/material.dart';
import '../models/brew.dart';
import '../models/coffee_bag.dart';
import '../models/equipment.dart';
import '../state/app_data.dart';
import '../theme.dart';
import '../utils/format.dart';
import 'common.dart';

// A brew in a list, Strava-activity style: what, when, the key numbers, rating.
class BrewCard extends StatelessWidget {
  final Brew brew;
  final AppData data;
  final VoidCallback? onTap;

  const BrewCard({super.key, required this.brew, required this.data, this.onTap});

  @override
  Widget build(BuildContext context) {
    final CoffeeBag? bag = data.bag(brew.coffeeBagId);
    final Brewer? brewer = data.brewer(brew.brewerId);
    final Grinder? grinder = data.grinder(brew.grinderId);

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              IconTile(brewTypeIcon(brewer?.brewType), size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      bag?.originLabel ?? 'Unknown coffee',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      <String?>[formatRelative(brew.brewDatetime), prettyBrewType(brewer?.brewType), bag?.roaster]
                          .whereType<String>()
                          .join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: BrewColors.muted, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              if (brew.rating != null) RatingBadge(rating: brew.rating, compact: true),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(child: StatValue(value: formatRatio(brew.ratio), label: 'Ratio', size: 17)),
              Expanded(child: StatValue(value: brew.waterTempC == null ? '–' : '${formatNum(brew.waterTempC)}°', label: 'Temp', size: 17)),
              Expanded(child: StatValue(value: formatSeconds(brew.brewTimeSecs), label: 'Time', size: 17)),
              Expanded(child: StatValue(value: brew.grindSetting ?? '–', label: grinder?.name ?? 'Grind', size: 17)),
            ],
          ),
          if (brew.review != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              brew.review!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13.5, height: 1.35),
            ),
          ],
          if (brew.brewHash != null) ...<Widget>[
            const SizedBox(height: 10),
            Text(brew.brewHash!, style: const TextStyle(color: BrewColors.muted, fontSize: 11.5, letterSpacing: 0.5)),
          ],
        ],
      ),
    );
  }
}
