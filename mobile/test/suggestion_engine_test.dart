import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/brew.dart';
import 'package:mobile/services/suggestion_engine.dart';

import 'test_helpers.dart';

void main() {
  Tweak? tweak(Suggestion s, TweakField f) {
    for (final Tweak t in s.tweaks) {
      if (t.field == f) return t;
    }
    return null;
  }

  test('fruitiness without history: cooler and a touch coarser', () {
    final Brew base = brew(id: 1, grind: '4.5', temp: 93, rating: 'good');
    final Suggestion s = suggest(goal: TasteGoal.fruitiness, base: base, history: <Brew>[base]);

    expect(tweak(s, TweakField.temp)!.to, 91);
    expect(tweak(s, TweakField.grind)!.to, closeTo(4.7, 1e-9));
    expect(tweak(s, TweakField.grind)!.title, 'Grind a little coarser');
    expect(s.basis, contains('general'));
  });

  test('moves toward the grind of your best brews of the bag first', () {
    final Brew base = brew(id: 1, grind: '4.0', temp: 93, rating: 'ok');
    final List<Brew> history = <Brew>[
      base,
      brew(id: 2, grind: '4.4', temp: 93, rating: 'excellent'),
      brew(id: 3, grind: '4.6', temp: 93, rating: 'good'),
      brew(id: 4, grind: '3.8', temp: 93, rating: 'bad'),
    ];
    final Suggestion s = suggest(goal: TasteGoal.sweetness, base: base, history: history);

    expect(s.tweaks.first.field, TweakField.grind);
    expect(s.tweaks.first.to, closeTo(4.5, 1e-9));
    expect(s.basis, contains('2 of your higher-rated brews'));
  });

  test('never more than two tweaks', () {
    final Brew base = brew(id: 1, grind: '4.0', temp: 89, rating: 'ok');
    final List<Brew> history = <Brew>[
      base,
      brew(id: 2, grind: '4.6', temp: 94, rating: 'excellent'),
      brew(id: 3, grind: '4.6', temp: 94, rating: 'excellent'),
    ];
    for (final TasteGoal g in TasteGoal.values) {
      expect(suggest(goal: g, base: base, history: history).tweaks.length, lessThanOrEqualTo(2));
    }
  });

  test('espresso body shortens the ratio and grinds finer', () {
    final Brew base = brew(id: 1, grind: '8', temp: 93, dose: 18, water: 36, rating: 'good');
    final Suggestion s = suggest(goal: TasteGoal.body, base: base, history: <Brew>[base], espresso: true);

    expect(tweak(s, TweakField.water)!.to, 32);
    expect(tweak(s, TweakField.grind)!.to, closeTo(7.5, 1e-9));
    expect(tweak(s, TweakField.dose), isNull);
  });

  test('filter body adds coffee', () {
    final Brew base = brew(id: 1, grind: '4.5', temp: 93, rating: 'good');
    final Suggestion s = suggest(goal: TasteGoal.body, base: base, history: <Brew>[base]);
    expect(tweak(s, TweakField.dose)!.to, 16);
  });

  test('temperature is clamped for less bitter', () {
    final Brew base = brew(id: 1, grind: '4.5', temp: 86, rating: 'so-so');
    final Suggestion s = suggest(goal: TasteGoal.lessBitter, base: base, history: <Brew>[base]);
    expect(tweak(s, TweakField.temp)!.to, 85);
  });

  test('apply returns new values per field', () {
    final Brew base = brew(id: 1, grind: '4.5', temp: 93);
    final Suggestion s = suggest(goal: TasteGoal.fruitiness, base: base, history: <Brew>[base]);
    expect(s.apply(base)[TweakField.temp], 91);
  });

  test('no data-driven tweak when today\'s cup is already as good as the best', () {
    final Brew base = brew(id: 1, grind: '4.5', temp: 93, rating: 'excellent');
    final Suggestion s = suggest(
      goal: TasteGoal.fruitiness,
      base: base,
      history: <Brew>[
        base,
        brew(id: 2, grind: '4.3', temp: 93, rating: 'excellent'),
        brew(id: 3, grind: '4.3', temp: 93, rating: 'good'),
      ],
    );
    // Only the fruitiness rule: cooler and a touch coarser, not "finer toward 4.3"
    expect(s.tweaks.map((Tweak t) => t.field), <TweakField>[TweakField.temp, TweakField.grind]);
    expect(s.tweaks.last.to, greaterThan(4.5));
  });
}
