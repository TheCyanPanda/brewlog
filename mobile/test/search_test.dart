import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/brew.dart';
import 'package:mobile/models/coffee_bag.dart';
import 'package:mobile/models/equipment.dart';
import 'package:mobile/services/search.dart';

import 'test_helpers.dart';

CoffeeBag _bag(int id, String roaster, String country, String roast, {String? region, String process = 'Washed'}) => CoffeeBag(
      id: id,
      userId: 1,
      bagHash: 'B-$id',
      roaster: roaster,
      originCountry: country,
      originRegion: region,
      roastLevel: roast,
      process: process,
      tasteNotes: const <String>['blueberry'],
      createdAt: DateTime(2026, 9, 1),
    );

void main() {
  final CoffeeBag morgon = _bag(1, 'Morgon Coffee Roasters', 'Ethiopia', 'Light', region: 'Yirgacheffe');
  final CoffeeBag raven = _bag(2, 'Kafferäven', 'Brazil', 'Medium-dark', process: 'Natural');
  final Grinder zp6 = Grinder(id: 7, userId: 1, name: 'ZP6 Special', createdAt: DateTime(2026));

  test('free text matches roaster, origin and roast level, all words required', () {
    expect(bagMatches(morgon, const SearchFilters(text: 'morgon')), isTrue);
    expect(bagMatches(morgon, const SearchFilters(text: 'yirgacheffe light')), isTrue);
    expect(bagMatches(morgon, const SearchFilters(text: 'ethiopia dark')), isFalse);
    expect(bagMatches(raven, const SearchFilters(text: 'medium-dark')), isTrue);
  });

  test('accents are ignored', () {
    expect(bagMatches(raven, const SearchFilters(text: 'kafferaven')), isTrue);
    expect(bagMatches(raven, const SearchFilters(text: 'KAFFERÄVEN')), isTrue);
  });

  test('roaster, origin and roast level filters are exact', () {
    expect(bagMatches(morgon, const SearchFilters(roaster: 'Morgon Coffee Roasters')), isTrue);
    expect(bagMatches(morgon, const SearchFilters(origin: 'Brazil')), isFalse);
    expect(bagMatches(raven, const SearchFilters(roastLevel: 'Medium-dark', origin: 'Brazil')), isTrue);
  });

  test('bag grinder filter uses the grinders of its brews', () {
    const SearchFilters f = SearchFilters(grinderId: 7);
    expect(bagMatches(morgon, f, grindersUsed: <int>{7}), isTrue);
    expect(bagMatches(morgon, f, grindersUsed: <int>{3}), isFalse);
  });

  test('brews match on their bag, grinder and own notes', () {
    final Brew b = Brew(
      id: 1,
      userId: 1,
      coffeeBagId: 1,
      grinderId: 7,
      brewDatetime: DateTime(2026, 10, 1),
      review: 'Juicy, clear blueberry',
      createdAt: DateTime(2026, 10, 1),
    );
    expect(brewMatches(b, const SearchFilters(text: 'morgon'), bag: morgon, grinder: zp6), isTrue);
    expect(brewMatches(b, const SearchFilters(text: 'juicy'), bag: morgon, grinder: zp6), isTrue);
    expect(brewMatches(b, const SearchFilters(text: 'zp6'), bag: morgon, grinder: zp6), isTrue);
    expect(brewMatches(b, const SearchFilters(grinderId: 7), bag: morgon), isTrue);
    expect(brewMatches(b, const SearchFilters(grinderId: 8), bag: morgon), isFalse);
    expect(brewMatches(b, const SearchFilters(roastLevel: 'Dark'), bag: morgon), isFalse);
    // A brew without a bag never matches a bag-field filter
    expect(brewMatches(brew(id: 2), const SearchFilters(roaster: 'Morgon Coffee Roasters')), isFalse);
  });

  test('roast levels are listed in roast order', () {
    expect(roastLevels(<CoffeeBag>[raven, morgon, _bag(3, 'X', 'Kenya', 'Medium')]), <String>['Light', 'Medium', 'Medium-dark']);
  });

  test('active filter count excludes free text', () {
    expect(const SearchFilters(text: 'x', roaster: 'a', grinderId: 1).activeCount, 2);
    expect(SearchFilters.none.isEmpty, isTrue);
  });
}
