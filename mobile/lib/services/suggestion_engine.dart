// "What should I change to get more X?" — rule-based suggestions grounded in
// the user's own brews of the same bag. Pure Dart, unit tested.
//
// Two sources, in order:
//  1. Your data: if your best-rated brews of this bag used a noticeably
//     different grind or temperature than your latest one, move toward them.
//  2. Brewing rules of thumb for the chosen goal (e.g. fruitiness: a little
//     cooler and coarser keeps the bright acids and avoids bitter extraction).
// At most two tweaks, so it stays "change one or two variables at a time".
//
// Grind direction: higher setting = coarser (true for ZP6, Comandante-style
// numbering and most stepless espresso grinders).

import '../models/brew.dart';
import '../utils/format.dart';

enum TasteGoal { fruitiness, sweetness, body, lessBitter }

extension TasteGoalLabel on TasteGoal {
  String get label {
    switch (this) {
      case TasteGoal.fruitiness: return 'Fruitiness';
      case TasteGoal.sweetness: return 'Sweetness';
      case TasteGoal.body: return 'Body';
      case TasteGoal.lessBitter: return 'Less bitter';
    }
  }
}

enum TweakField { grind, temp, dose, water }

class Tweak {
  final TweakField field;
  final double from;
  final double to;
  final String why;

  const Tweak({required this.field, required this.from, required this.to, required this.why});

  String get title {
    switch (field) {
      case TweakField.grind:
        return to > from ? 'Grind a little coarser' : 'Grind a little finer';
      case TweakField.temp:
        return to < from ? 'Lower the temperature' : 'Raise the temperature';
      case TweakField.dose:
        return to > from ? 'Use a bit more coffee' : 'Use a bit less coffee';
      case TweakField.water:
        return to > from ? 'Use a bit more water' : 'Use a bit less water';
    }
  }

  String get fieldLabel {
    switch (field) {
      case TweakField.grind: return 'Grind';
      case TweakField.temp: return 'Temperature';
      case TweakField.dose: return 'Dose';
      case TweakField.water: return 'Water';
    }
  }

  String get unit {
    switch (field) {
      case TweakField.grind: return '';
      case TweakField.temp: return ' °C';
      case TweakField.dose: return ' g';
      case TweakField.water: return ' g';
    }
  }
}

class Suggestion {
  final TasteGoal goal;
  final List<Tweak> tweaks;
  final String basis; // one line on what it is based on

  const Suggestion({required this.goal, required this.tweaks, required this.basis});

  /// The base brew with all tweaks applied, as plain values for a new brew.
  Map<TweakField, double> apply(Brew base) => <TweakField, double>{
        for (final Tweak t in tweaks) t.field: t.to,
      };
}

double _round1(double v) => (v * 10).roundToDouble() / 10;

Suggestion suggest({
  required TasteGoal goal,
  required Brew base,           // the brew to improve on (usually the latest of the bag)
  required List<Brew> history,  // all brews of the same bag
  bool espresso = false,
}) {
  final List<Tweak> tweaks = <Tweak>[];
  final double? grind = base.grindValue;
  final double? temp = base.waterTempC;
  final double? dose = base.coffeeGrams;
  final double? water = base.waterGrams;

  // 1. Learn from your own best cups of this bag
  final List<Brew> best = history
      .where((Brew b) => b.id != base.id && (ratingScore(b.rating) ?? 0) >= 4)
      .toList();
  String basis = 'Based on general brewing principles.';
  // Only learn from your best cups if today's cup wasn't already as good as them
  final int baseScore = ratingScore(base.rating) ?? 0;
  final double bestScore = best.isEmpty
      ? 0
      : best.map((Brew b) => ratingScore(b.rating)!).reduce((int a, int b) => a + b) / best.length;
  if (baseScore >= bestScore && best.isNotEmpty) {
    basis = 'Today\'s cup is already as good as your best of this bag, so this is a goal tweak.';
  } else if (best.length >= 2) {
    final List<double> bg = best.map((Brew b) => b.grindValue).whereType<double>().toList();
    final List<double> bt = best.map((Brew b) => b.waterTempC).whereType<double>().toList();
    final double? bestGrind = bg.isEmpty ? null : _round1(bg.reduce((double a, double b) => a + b) / bg.length);
    final double? bestTemp = bt.isEmpty ? null : (bt.reduce((double a, double b) => a + b) / bt.length).roundToDouble();
    basis = 'Based on ${best.length} of your higher-rated brews of this bag.';

    if (grind != null && bestGrind != null && (bestGrind - grind).abs() >= 0.15) {
      tweaks.add(Tweak(
        field: TweakField.grind,
        from: grind,
        to: bestGrind,
        why: 'Your best cups of this bag were around ${formatNum(bestGrind)}.',
      ));
    }
    if (temp != null && bestTemp != null && (bestTemp - temp).abs() >= 1.5) {
      tweaks.add(Tweak(
        field: TweakField.temp,
        from: temp,
        to: bestTemp,
        why: 'Your best cups were brewed at about ${bestTemp.toStringAsFixed(0)} °C.',
      ));
    }
  }

  // 2. Goal-specific rule of thumb, for whatever isn't already being changed
  bool has(TweakField f) => tweaks.any((Tweak t) => t.field == f);
  void add(TweakField f, double? from, double delta, String why, {double? min, double? max}) {
    if (from == null || has(f) || tweaks.length >= 2) return;
    double to = from + delta;
    if (min != null && to < min) to = min;
    if (max != null && to > max) to = max;
    if (to == from) return;
    tweaks.add(Tweak(field: f, from: from, to: f == TweakField.grind ? _round1(to) : to, why: why));
  }

  final double grindStep = espresso ? 0.5 : 0.2;
  switch (goal) {
    case TasteGoal.fruitiness:
      add(TweakField.temp, temp, -2, 'Slightly cooler water keeps the bright, fruity acids in focus.', min: 85);
      add(TweakField.grind, grind, grindStep, 'A touch coarser avoids over-extracting the heavier compounds that mute fruit.');
      break;
    case TasteGoal.sweetness:
      add(TweakField.grind, grind, -grindStep, 'A little finer extracts more of the sugars.');
      add(TweakField.temp, temp, 1, 'Slightly hotter water helps dissolve the sweetness.', max: 96);
      break;
    case TasteGoal.body:
      if (espresso) {
        add(TweakField.water, water, -4, 'A shorter ratio gives a thicker, heavier shot.', min: 24);
      } else {
        add(TweakField.dose, dose, 1, 'More coffee for the same water gives a fuller cup.');
      }
      add(TweakField.grind, grind, -grindStep, 'Finer grind adds texture and body.');
      break;
    case TasteGoal.lessBitter:
      add(TweakField.grind, grind, grindStep * 1.5, 'Coarser grind reduces over-extraction, the usual cause of bitterness.');
      add(TweakField.temp, temp, -2, 'Cooler water extracts less of the bitter compounds.', min: 85);
      break;
  }

  return Suggestion(goal: goal, tweaks: tweaks, basis: basis);
}
