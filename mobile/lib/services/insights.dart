// Pure Dart statistics over the user's own brews: best brews, taste profile,
// start points for new bags and the yearly summary. No Flutter imports, so it
// is easy to unit test.

import '../models/brew.dart';
import '../models/coffee_bag.dart';
import '../models/equipment.dart';
import '../utils/format.dart';

// Average rating score (1..5) of rated brews, null if none are rated
double? averageScore(Iterable<Brew> brews) {
  final List<int> scores = brews.map((Brew b) => ratingScore(b.rating)).whereType<int>().toList();
  if (scores.isEmpty) return null;
  return scores.reduce((int a, int b) => a + b) / scores.length;
}

double? averageRatio(Iterable<Brew> brews) {
  final List<double> r = brews.map((Brew b) => b.ratio).whereType<double>().toList();
  return r.isEmpty ? null : r.reduce((double a, double b) => a + b) / r.length;
}

// Highest rated brew; ties go to the most recent
Brew? bestBrew(Iterable<Brew> brews) {
  Brew? best;
  for (final Brew b in brews) {
    final int s = ratingScore(b.rating) ?? 0;
    final int bs = ratingScore(best?.rating) ?? -1;
    if (best == null || s > bs || (s == bs && b.brewDatetime.isAfter(best.brewDatetime))) best = b;
  }
  return (best != null && ratingScore(best.rating) != null) ? best : null;
}

// Rating vs days since roast, for the bag history chart
List<(double, double)> ratingByRestDays(CoffeeBag bag, Iterable<Brew> brews) {
  if (bag.roastDate == null) return <(double, double)>[];
  return <(double, double)>[
    for (final Brew b in brews)
      if (ratingScore(b.rating) != null)
        (b.brewDatetime.difference(bag.roastDate!).inDays.toDouble(), ratingScore(b.rating)!.toDouble()),
  ];
}

// Grind setting vs rating, for the dial-in chart
List<(double, double)> ratingByGrind(Iterable<Brew> brews) => <(double, double)>[
      for (final Brew b in brews)
        if (b.grindValue != null && ratingScore(b.rating) != null)
          (b.grindValue!, ratingScore(b.rating)!.toDouble()),
    ];

// How many of these brews were made this calendar month
int brewsThisMonth(Iterable<Brew> brews, {DateTime? now}) {
  final DateTime n = now ?? DateTime.now();
  return brews.where((Brew b) => b.brewDatetime.year == n.year && b.brewDatetime.month == n.month).length;
}

// Consecutive days (ending today or yesterday) with at least one brew
int brewStreak(Iterable<Brew> brews, {DateTime? now}) {
  final DateTime n = now ?? DateTime.now();
  final Set<DateTime> days = brews
      .map((Brew b) => DateTime(b.brewDatetime.year, b.brewDatetime.month, b.brewDatetime.day))
      .toSet();
  DateTime day = DateTime(n.year, n.month, n.day);
  if (!days.contains(day)) day = day.subtract(const Duration(days: 1));
  int streak = 0;
  while (days.contains(day)) {
    streak++;
    day = day.subtract(const Duration(days: 1));
  }
  return streak;
}

// ---- Grouping ----

// Count of brews per key, sorted by count (descending)
List<MapEntry<String, int>> countBy(Iterable<Brew> brews, String? Function(Brew) keyOf) {
  final Map<String, int> counts = <String, int>{};
  for (final Brew b in brews) {
    final String? k = keyOf(b);
    if (k != null && k.isNotEmpty) counts[k] = (counts[k] ?? 0) + 1;
  }
  return counts.entries.toList()..sort((MapEntry<String, int> a, MapEntry<String, int> b) => b.value - a.value);
}

// Average rating per key (only keys with >= minBrews rated brews), best first
List<MapEntry<String, double>> averageScoreBy(Iterable<Brew> brews, String? Function(Brew) keyOf, {int minBrews = 2}) {
  final Map<String, List<int>> groups = <String, List<int>>{};
  for (final Brew b in brews) {
    final String? k = keyOf(b);
    final int? s = ratingScore(b.rating);
    if (k != null && s != null) (groups[k] ??= <int>[]).add(s);
  }
  final List<MapEntry<String, double>> out = <MapEntry<String, double>>[
    for (final MapEntry<String, List<int>> e in groups.entries)
      if (e.value.length >= minBrews) MapEntry<String, double>(e.key, e.value.reduce((int a, int b) => a + b) / e.value.length),
  ];
  out.sort((MapEntry<String, double> a, MapEntry<String, double> b) => b.value.compareTo(a.value));
  return out;
}

// East Africa, Latin America ... for the taste profile
String regionOf(String? country) {
  switch (country) {
    case 'Ethiopia': case 'Kenya': case 'Rwanda': case 'Burundi': case 'Uganda': case 'Tanzania':
      return 'East Africa';
    case 'Colombia': case 'Brazil': case 'Peru': case 'Bolivia': case 'Ecuador':
      return 'South America';
    case 'Panama': case 'Costa Rica': case 'Guatemala': case 'Honduras': case 'El Salvador': case 'Nicaragua': case 'Mexico':
      return 'Central America';
    case 'Indonesia': case 'Yemen': case 'India': case 'Papua New Guinea': case 'China':
      return 'Asia & Pacific';
    default:
      return country ?? 'Unknown';
  }
}

// ---- Taste profile: what the user rates highly ----

class TasteProfile {
  final String? roastLevel;
  final String? process;
  final String? region;
  final List<String> notes; // most common taste notes in top-rated bags
  final int basedOn;        // number of top-rated brews

  const TasteProfile({this.roastLevel, this.process, this.region, this.notes = const <String>[], this.basedOn = 0});

  List<String> get tags => <String?>[roastLevel == null ? null : '$roastLevel roast', process, region, ...notes]
      .whereType<String>()
      .toList();
}

TasteProfile tasteProfile(List<Brew> brews, CoffeeBag? Function(int?) bagOf) {
  final List<Brew> top = brews.where((Brew b) => (ratingScore(b.rating) ?? 0) >= 4).toList();
  if (top.isEmpty) return const TasteProfile();

  String? mostCommon(String? Function(CoffeeBag) f) {
    final List<MapEntry<String, int>> c = countBy(top, (Brew b) {
      final CoffeeBag? bag = bagOf(b.coffeeBagId);
      return bag == null ? null : f(bag);
    });
    return c.isEmpty ? null : c.first.key;
  }

  // Taste notes of your highest-rated bags (by average score, not brew count,
  // so a bag you brew a lot but only rate "good" doesn't dominate)
  final List<String> topNotes = <String>[];
  for (final MapEntry<String, double> e in averageScoreBy(brews, (Brew b) => b.coffeeBagId?.toString(), minBrews: 3)) {
    for (final String n in bagOf(int.parse(e.key))?.tasteNotes ?? const <String>[]) {
      if (topNotes.length < 3 && !topNotes.contains(n)) topNotes.add(n);
    }
    if (topNotes.length >= 3) break;
  }

  return TasteProfile(
    roastLevel: mostCommon((CoffeeBag b) => b.roastLevel),
    process: mostCommon((CoffeeBag b) => b.process),
    region: mostCommon((CoffeeBag b) => b.originCountry == null ? null : regionOf(b.originCountry)),
    notes: topNotes,
    basedOn: top.length,
  );
}

// ---- Start point for a new bag ----

class StartPoint {
  final String? grindSetting;
  final double? waterTempC;
  final int basedOn;   // number of brews it is derived from
  final String reason; // "Based on 12 good brews of washed light roasts"

  const StartPoint({this.grindSetting, this.waterTempC, required this.basedOn, required this.reason});
}

/// Suggests grind and temperature for a bag that has no brews yet, from the
/// user's good brews (score >= 4) of similar coffees on the same kind of brewer.
StartPoint? startPointFor(
  CoffeeBag bag,
  List<Brew> brews,
  CoffeeBag? Function(int?) bagOf,
  Brewer? Function(int?) brewerOf, {
  bool espresso = false,
}) {
  final List<Brew> good = brews.where((Brew b) {
    if ((ratingScore(b.rating) ?? 0) < 4 || b.coffeeBagId == bag.id) return false;
    return (brewerOf(b.brewerId)?.isEspresso ?? false) == espresso;
  }).toList();
  if (good.isEmpty) return null;

  // Most similar first: same process + roast level, then same process, then anything
  final List<(String, bool Function(CoffeeBag))> tiers = <(String, bool Function(CoffeeBag))>[
    (
      '${(bag.process ?? '').toLowerCase()} ${(bag.roastLevel ?? '').toLowerCase()} roasts'.trim(),
      (CoffeeBag o) => o.process == bag.process && o.roastLevel == bag.roastLevel,
    ),
    ('${(bag.process ?? '').toLowerCase()} coffees'.trim(), (CoffeeBag o) => o.process == bag.process),
    ('your coffees', (CoffeeBag o) => true),
  ];

  for (final (String label, bool Function(CoffeeBag) similar) in tiers) {
    final List<Brew> match = good.where((Brew b) {
      final CoffeeBag? o = bagOf(b.coffeeBagId);
      return o != null && similar(o);
    }).toList();
    if (match.length < 3 && label != 'your coffees') continue;
    if (match.isEmpty) return null;

    final List<double> grinds = match.map((Brew b) => b.grindValue).whereType<double>().toList();
    final List<double> temps = match.map((Brew b) => b.waterTempC).whereType<double>().toList();
    double avg(List<double> v) => v.reduce((double a, double b) => a + b) / v.length;

    return StartPoint(
      grindSetting: grinds.isEmpty ? null : avg(grinds).toStringAsFixed(1),
      waterTempC: temps.isEmpty ? null : avg(temps).roundToDouble(),
      basedOn: match.length,
      reason: 'Based on ${match.length} good brews of $label',
    );
  }
  return null;
}

// ---- Your coffee year (wrapped) ----

class YearStats {
  final int year;
  final int brews;
  final int bags;
  final int countries;
  final int washed;
  final List<MapEntry<String, int>> byMethod;  // "V60" -> 86
  final List<MapEntry<String, int>> byCountry;
  final CoffeeBag? mostBrewedBag;
  final int mostBrewedCount;
  final CoffeeBag? topRatedBag;
  final int excellentCups;
  final double? avgRatio;

  const YearStats({
    required this.year,
    required this.brews,
    required this.bags,
    required this.countries,
    required this.washed,
    required this.byMethod,
    required this.byCountry,
    required this.mostBrewedBag,
    required this.mostBrewedCount,
    required this.topRatedBag,
    required this.excellentCups,
    required this.avgRatio,
  });
}

YearStats yearStats(
  int year,
  List<Brew> allBrews,
  CoffeeBag? Function(int?) bagOf,
  Brewer? Function(int?) brewerOf,
) {
  final List<Brew> brews = allBrews.where((Brew b) => b.brewDatetime.year == year).toList();
  final Set<int> bagIds = brews.map((Brew b) => b.coffeeBagId).whereType<int>().toSet();
  final List<CoffeeBag> bags = bagIds.map(bagOf).whereType<CoffeeBag>().toList();

  final List<MapEntry<String, int>> perBag = countBy(brews, (Brew b) => b.coffeeBagId?.toString());
  final List<MapEntry<String, double>> bagScores =
      averageScoreBy(brews, (Brew b) => b.coffeeBagId?.toString(), minBrews: 3);

  return YearStats(
    year: year,
    brews: brews.length,
    bags: bags.length,
    countries: bags.map((CoffeeBag b) => b.originCountry).whereType<String>().toSet().length,
    washed: brews.where((Brew b) => bagOf(b.coffeeBagId)?.process?.toLowerCase() == 'washed').length,
    byMethod: countBy(brews, (Brew b) => prettyBrewType(brewerOf(b.brewerId)?.brewType)),
    byCountry: countBy(brews, (Brew b) => bagOf(b.coffeeBagId)?.originCountry),
    mostBrewedBag: perBag.isEmpty ? null : bagOf(int.parse(perBag.first.key)),
    mostBrewedCount: perBag.isEmpty ? 0 : perBag.first.value,
    topRatedBag: bagScores.isEmpty ? null : bagOf(int.parse(bagScores.first.key)),
    excellentCups: brews.where((Brew b) => b.rating == 'excellent').length,
    avgRatio: averageRatio(brews.where((Brew b) => !(brewerOf(b.brewerId)?.isEspresso ?? false))),
  );
}
