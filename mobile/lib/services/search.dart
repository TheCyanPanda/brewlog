// Search and filters for the Bags and Brews lists. Pure Dart, unit tested.
//
// Free text matches roaster, origin, region, roast level, process, variety,
// taste notes and IDs (and, for brews, brewer/grinder names and your notes).
// Every word must match something, so "kenya washed" narrows down.
// Accents are ignored: "kafferaven" finds "Kafferäven".

import '../models/brew.dart';
import '../models/coffee_bag.dart';
import '../models/equipment.dart';

class SearchFilters {
  final String text;
  final String? roaster;
  final String? origin;     // origin country
  final String? roastLevel;
  final int? grinderId;

  const SearchFilters({this.text = '', this.roaster, this.origin, this.roastLevel, this.grinderId});

  static const SearchFilters none = SearchFilters();

  // Number of active filters besides the free text (for the badge)
  int get activeCount =>
      <Object?>[roaster, origin, roastLevel, grinderId].where((Object? v) => v != null).length;

  bool get isEmpty => text.trim().isEmpty && activeCount == 0;

  SearchFilters copyWith({
    String? text,
    String? Function()? roaster,
    String? Function()? origin,
    String? Function()? roastLevel,
    int? Function()? grinderId,
  }) =>
      SearchFilters(
        text: text ?? this.text,
        roaster: roaster == null ? this.roaster : roaster(),
        origin: origin == null ? this.origin : origin(),
        roastLevel: roastLevel == null ? this.roastLevel : roastLevel(),
        grinderId: grinderId == null ? this.grinderId : grinderId(),
      );
}

// Lowercase and strip Swedish/common accents
String normalize(String s) {
  const Map<String, String> map = <String, String>{
    'å': 'a', 'ä': 'a', 'á': 'a', 'à': 'a', 'â': 'a',
    'ö': 'o', 'ó': 'o', 'ò': 'o', 'ô': 'o', 'ø': 'o',
    'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
    'í': 'i', 'ï': 'i', 'ú': 'u', 'ü': 'u', 'ñ': 'n', 'ç': 'c',
  };
  final StringBuffer out = StringBuffer();
  for (final String ch in s.toLowerCase().split('')) {
    out.write(map[ch] ?? ch);
  }
  return out.toString();
}

List<String> _tokens(String text) =>
    normalize(text).split(RegExp(r'\s+')).where((String t) => t.isNotEmpty).toList();

String _bagHaystack(CoffeeBag b) => normalize(<String?>[
      b.roaster,
      b.roasterOriginCity,
      b.originCountry,
      b.originRegion,
      b.roastLevel,
      b.roastLevel == null ? null : '${b.roastLevel} roast',
      b.process,
      b.variety,
      b.bagHash,
      ...?b.tasteNotes,
    ].whereType<String>().join(' | '));

bool _textMatches(String haystack, String text) => _tokens(text).every(haystack.contains);

bool _bagFieldsMatch(CoffeeBag? b, SearchFilters f) {
  if (f.roaster == null && f.origin == null && f.roastLevel == null) return true;
  if (b == null) return false;
  return (f.roaster == null || b.roaster == f.roaster) &&
      (f.origin == null || b.originCountry == f.origin) &&
      (f.roastLevel == null || b.roastLevel == f.roastLevel);
}

/// A bag matches the grinder filter if any of its brews used that grinder.
bool bagMatches(CoffeeBag b, SearchFilters f, {Set<int> grindersUsed = const <int>{}}) {
  if (!_bagFieldsMatch(b, f)) return false;
  if (f.grinderId != null && !grindersUsed.contains(f.grinderId)) return false;
  return _textMatches(_bagHaystack(b), f.text);
}

bool brewMatches(Brew br, SearchFilters f, {CoffeeBag? bag, Brewer? brewer, Grinder? grinder}) {
  if (!_bagFieldsMatch(bag, f)) return false;
  if (f.grinderId != null && br.grinderId != f.grinderId) return false;
  if (f.text.trim().isEmpty) return true;
  final String haystack = <String>[
    if (bag != null) _bagHaystack(bag),
    normalize(<String?>[br.brewHash, br.review, br.notes, br.filterPaper, brewer?.name, brewer?.brewType, grinder?.name]
        .whereType<String>()
        .join(' | ')),
  ].join(' | ');
  return _textMatches(haystack, f.text);
}

// Distinct non-empty values, sorted — the options in the filter sheet
List<String> distinctValues(Iterable<CoffeeBag> bags, String? Function(CoffeeBag) field) {
  final Set<String> values = bags.map(field).whereType<String>().where((String v) => v.isNotEmpty).toSet();
  return values.toList()..sort((String a, String b) => normalize(a).compareTo(normalize(b)));
}

// Roast levels in roast order, not alphabetical
const List<String> kRoastOrder = <String>['Light', 'Medium-light', 'Medium', 'Medium-dark', 'Dark'];

List<String> roastLevels(Iterable<CoffeeBag> bags) {
  final List<String> values = distinctValues(bags, (CoffeeBag b) => b.roastLevel);
  int rank(String v) {
    final int i = kRoastOrder.indexWhere((String r) => r.toLowerCase() == v.toLowerCase());
    return i < 0 ? kRoastOrder.length : i;
  }
  return values..sort((String a, String b) => rank(a).compareTo(rank(b)));
}
