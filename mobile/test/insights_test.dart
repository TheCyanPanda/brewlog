import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/brew.dart';
import 'package:mobile/models/coffee_bag.dart';
import 'package:mobile/models/equipment.dart';
import 'package:mobile/services/insights.dart';
import 'package:mobile/utils/format.dart';

import 'test_helpers.dart';

void main() {
  group('format', () {
    test('parseSeconds', () {
      expect(parseSeconds('3:10'), 190);
      expect(parseSeconds('190'), 190);
      expect(parseSeconds(''), isNull);
      expect(parseSeconds('x:10'), isNull);
    });

    test('formatRatio / formatSeconds / formatNum', () {
      expect(formatRatio(16.666), '1:16.7');
      expect(formatRatio(null), '–');
      expect(formatSeconds(190), '3:10');
      expect(formatNum(15.0), '15');
      expect(formatNum(15.5), '15.5');
    });

    test('rating scale', () {
      expect(ratingScore('excellent'), 5);
      expect(ratingScore('bad'), 1);
      expect(ratingScore(null), isNull);
      expect(ratingForScore(4.4), 'good');
      expect(ratingForScore(4.6), 'excellent');
    });
  });

  group('stats', () {
    test('averageScore ignores unrated brews', () {
      expect(averageScore(<Brew>[brew(rating: 'excellent'), brew(rating: 'ok'), brew()]), 4);
      expect(averageScore(<Brew>[brew()]), isNull);
    });

    test('bestBrew picks highest rating, newest on ties', () {
      final Brew older = brew(id: 1, rating: 'excellent', at: DateTime(2026, 9, 1));
      final Brew newer = brew(id: 2, rating: 'excellent', at: DateTime(2026, 9, 5));
      final Brew good = brew(id: 3, rating: 'good', at: DateTime(2026, 9, 9));
      expect(bestBrew(<Brew>[older, good, newer])!.id, 2);
      expect(bestBrew(<Brew>[brew()]), isNull);
    });

    test('brewStreak counts consecutive days ending today or yesterday', () {
      final DateTime now = DateTime(2026, 10, 11, 12);
      final List<Brew> brews = <Brew>[
        brew(at: DateTime(2026, 10, 10, 8)),
        brew(at: DateTime(2026, 10, 9, 8)),
        brew(at: DateTime(2026, 10, 9, 15)),
        brew(at: DateTime(2026, 10, 7, 8)),
      ];
      expect(brewStreak(brews, now: now), 2);
      expect(brewStreak(<Brew>[brew(at: DateTime(2026, 10, 1))], now: now), 0);
    });

    test('brewsThisMonth', () {
      final DateTime now = DateTime(2026, 10, 11);
      expect(brewsThisMonth(<Brew>[brew(at: DateTime(2026, 10, 2)), brew(at: DateTime(2026, 9, 30))], now: now), 1);
    });
  });

  group('startPointFor', () {
    final Map<int, CoffeeBag> bags = <int, CoffeeBag>{
      1: bag(1, process: 'Washed', roast: 'Light'),
      2: bag(2, process: 'Natural', roast: 'Light'),
      9: bag(9, process: 'Washed', roast: 'Light', status: 'unopened'),
    };
    final Map<int, Brewer> brewers = <int, Brewer>{1: brewer(1), 2: brewer(2, method: 'espresso', type: 'espresso')};
    CoffeeBag? bagOf(int? id) => bags[id];
    Brewer? brewerOf(int? id) => brewers[id];

    test('uses good brews of similar coffees on the same kind of brewer', () {
      final List<Brew> brews = <Brew>[
        brew(bagId: 1, brewerId: 1, grind: '4.4', temp: 93, rating: 'excellent'),
        brew(bagId: 1, brewerId: 1, grind: '4.6', temp: 94, rating: 'good'),
        brew(bagId: 1, brewerId: 1, grind: '4.5', temp: 92, rating: 'good'),
        brew(bagId: 1, brewerId: 1, grind: '3.0', temp: 99, rating: 'bad'),      // not good
        brew(bagId: 2, brewerId: 1, grind: '5.5', temp: 90, rating: 'excellent'), // other process
        brew(bagId: 1, brewerId: 2, grind: '8', temp: 93, rating: 'excellent'),   // espresso
      ];
      final StartPoint sp = startPointFor(bags[9]!, brews, bagOf, brewerOf)!;
      expect(sp.grindSetting, '4.5');
      expect(sp.waterTempC, 93);
      expect(sp.basedOn, 3);
      expect(sp.reason, contains('washed light roasts'));
    });

    test('null when there are no good brews', () {
      expect(startPointFor(bags[9]!, <Brew>[brew(bagId: 1, brewerId: 1, rating: 'ok')], bagOf, brewerOf), isNull);
    });
  });

  test('tasteProfile and yearStats', () {
    final Map<int, CoffeeBag> bags = <int, CoffeeBag>{
      1: bag(1, process: 'Washed', roast: 'Light', country: 'Ethiopia', notes: <String>['jasmine', 'blueberry']),
      2: bag(2, process: 'Natural', roast: 'Medium', country: 'Brazil', notes: <String>['cocoa']),
    };
    final Map<int, Brewer> brewers = <int, Brewer>{1: brewer(1), 2: brewer(2, method: 'espresso', type: 'espresso')};
    final List<Brew> brews = <Brew>[
      brew(bagId: 1, brewerId: 1, rating: 'excellent', at: DateTime(2026, 3, 1)),
      brew(bagId: 1, brewerId: 1, rating: 'excellent', at: DateTime(2026, 3, 2)),
      brew(bagId: 1, brewerId: 1, rating: 'good', at: DateTime(2026, 3, 3)),
      brew(bagId: 2, brewerId: 2, rating: 'ok', at: DateTime(2026, 4, 1)),
      brew(bagId: 2, brewerId: 2, rating: 'ok', at: DateTime(2025, 12, 1)), // other year
    ];

    final TasteProfile p = tasteProfile(brews, (int? id) => bags[id]);
    expect(p.process, 'Washed');
    expect(p.region, 'East Africa');
    expect(p.basedOn, 3);
    expect(p.tags, contains('Light roast'));

    final YearStats y = yearStats(2026, brews, (int? id) => bags[id], (int? id) => brewers[id]);
    expect(y.brews, 4);
    expect(y.bags, 2);
    expect(y.countries, 2);
    expect(y.washed, 3);
    expect(y.excellentCups, 2);
    expect(y.byMethod.first.key, 'V60');
    expect(y.mostBrewedBag!.id, 1);
    expect(y.topRatedBag!.id, 1);
  });
}
