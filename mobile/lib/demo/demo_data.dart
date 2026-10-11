// Static example data for the community and partner previews (feed, map,
// featured roaster, roaster insights). Nothing here comes from the backend.
//
// People, cafés, shops and the partner roaster "Nordlys Kafferosteri" are
// fictional. The real Swedish roasters on the map only carry name, city, type
// and an approximate position — no ratings or other claims are invented for them.
import 'dart:math' as math;

import '../models/brew.dart';

// ---------------- Feed ----------------

class FeedPost {
  final String author;
  final bool isFriend;
  final String timeAgo;      // "2 h ago"
  final String brewType;     // 'v60' | 'aeropress' | 'espresso'
  final String originCountry;
  final String originRegion;
  final String process;
  final String roaster;
  final int daysOffRoast;
  final double coffeeGrams;
  final double waterGrams;
  final double waterTempC;
  final int brewTimeSecs;
  final String grinder;
  final String grindSetting;
  final String? filterPaper;
  final String recipeName;
  final List<BrewStep> steps;
  final String note;
  final String rating;
  final String brewId;       // "NKR-0042-B003"
  final int likes;
  final int comments;
  final String? videoLength; // "0:12" when the post has a short clip
  final String? photo;       // asset image of the cup/setup, null = text-only post

  const FeedPost({
    required this.author,
    required this.isFriend,
    required this.timeAgo,
    required this.brewType,
    required this.originCountry,
    required this.originRegion,
    required this.process,
    required this.roaster,
    required this.daysOffRoast,
    required this.coffeeGrams,
    required this.waterGrams,
    required this.waterTempC,
    required this.brewTimeSecs,
    required this.grinder,
    required this.grindSetting,
    this.filterPaper,
    required this.recipeName,
    this.steps = const <BrewStep>[],
    required this.note,
    required this.rating,
    required this.brewId,
    required this.likes,
    required this.comments,
    this.videoLength,
    this.photo,
  });

  double get ratio => waterGrams / coffeeGrams;
}

const List<BrewStep> _v60Steps = <BrewStep>[
  BrewStep(name: 'Bloom', durationSecs: 45, waterMl: 50),
  BrewStep(name: 'Pour 1', durationSecs: 30, waterMl: 100),
  BrewStep(name: 'Pour 2', durationSecs: 30, waterMl: 100),
];

const List<BrewStep> _fourSixSteps = <BrewStep>[
  BrewStep(name: 'Pour 1', durationSecs: 45, waterMl: 60),
  BrewStep(name: 'Pour 2', durationSecs: 45, waterMl: 60),
  BrewStep(name: 'Pour 3', durationSecs: 45, waterMl: 60),
  BrewStep(name: 'Pour 4', durationSecs: 45, waterMl: 60),
  BrewStep(name: 'Pour 5', durationSecs: 45, waterMl: 60),
];

const List<FeedPost> kFeedPosts = <FeedPost>[
  FeedPost(
    author: 'Kaffevän',
    isFriend: true,
    timeAgo: '2 h ago',
    brewType: 'v60',
    originCountry: 'Ethiopia',
    originRegion: 'Yirgacheffe',
    process: 'Natural',
    roaster: 'Nordlys Kafferosteri',
    daysOffRoast: 12,
    coffeeGrams: 15,
    waterGrams: 250,
    waterTempC: 93,
    brewTimeSecs: 190,
    grinder: 'ZP6 Special',
    grindSetting: '4.5',
    filterPaper: 'Cafec Abaca',
    recipeName: 'Bloom + 2 pours',
    steps: _v60Steps,
    note: 'Clear blueberry and jasmine, would have liked a bit more acidity. Trying 4.3 next time.',
    rating: 'excellent',
    brewId: 'NKR-0042-B003',
    likes: 14,
    comments: 3,
    videoLength: '0:12',
    photo: 'assets/feed/pourover.jpg',
  ),
  FeedPost(
    author: 'Bryggare_92',
    isFriend: false,
    timeAgo: '5 h ago',
    brewType: 'aeropress',
    originCountry: 'Kenya',
    originRegion: 'Nyeri',
    process: 'Washed',
    roaster: 'Hamnens Kafferosteri',
    daysOffRoast: 18,
    coffeeGrams: 14,
    waterGrams: 210,
    waterTempC: 90,
    brewTimeSecs: 120,
    grinder: 'Comandante C40',
    grindSetting: '22 clicks',
    filterPaper: 'Aeropress paper',
    recipeName: 'Sweet Aeropress',
    note: 'Blackcurrant bomb. Inverted, 1:30 steep, gentle press. Super sweet as it cools.',
    rating: 'good',
    brewId: 'HKR-0017-B002',
    likes: 31,
    comments: 6,
    photo: 'assets/feed/cup.jpg',
  ),
  FeedPost(
    author: 'Anna Lindqvist',
    isFriend: true,
    timeAgo: 'Yesterday',
    brewType: 'espresso',
    originCountry: 'Colombia',
    originRegion: 'Huila',
    process: 'Washed',
    roaster: 'Fjällbacka Rosteri',
    daysOffRoast: 9,
    coffeeGrams: 18,
    waterGrams: 38,
    waterTempC: 93,
    brewTimeSecs: 29,
    grinder: 'Eureka Mignon',
    grindSetting: '7.5',
    recipeName: 'Espresso 1:2.1',
    note: 'Finally dialed in. Caramel and red apple, syrupy body. Latte art is still a work in progress.',
    rating: 'excellent',
    brewId: 'FR-0009-B005',
    likes: 22,
    comments: 4,
    photo: 'assets/feed/latte.jpg',
  ),
  FeedPost(
    author: 'Jonas Berg',
    isFriend: false,
    timeAgo: 'Yesterday',
    brewType: 'v60',
    originCountry: 'Panama',
    originRegion: 'Boquete',
    process: 'Washed',
    roaster: 'Nordlys Kafferosteri',
    daysOffRoast: 21,
    coffeeGrams: 20,
    waterGrams: 300,
    waterTempC: 94,
    brewTimeSecs: 215,
    grinder: 'ZP6 Special',
    grindSetting: '4.8',
    filterPaper: 'Hario Tabbed',
    recipeName: '4:6 method',
    steps: _fourSixSteps,
    note: 'Gesha on a Sunday. Peach, honey, bergamot. The 4:6 split keeps it really clean.',
    rating: 'excellent',
    brewId: 'NKR-0031-B001',
    likes: 57,
    comments: 12,
    videoLength: '0:08',
    photo: 'assets/feed/setup.jpg',
  ),
  FeedPost(
    author: 'Mika S',
    isFriend: true,
    timeAgo: '2 days ago',
    brewType: 'v60',
    originCountry: 'Rwanda',
    originRegion: 'Nyamasheke',
    process: 'Washed',
    roaster: 'Hamnens Kafferosteri',
    daysOffRoast: 6,
    coffeeGrams: 15,
    waterGrams: 250,
    waterTempC: 95,
    brewTimeSecs: 170,
    grinder: '1Zpresso K-Ultra',
    grindSetting: '6.2',
    filterPaper: 'Cafec Abaca',
    recipeName: 'Quick single-cup V60',
    steps: _v60Steps,
    note: 'Too fresh still, a bit gassy and sharp. Will let it rest a few more days.',
    rating: 'ok',
    brewId: 'HKR-0022-B001',
    likes: 5,
    comments: 2,
  ),
];

// ---------------- Map ----------------

enum PlaceType { roaster, cafe, shop }

extension PlaceTypeLabel on PlaceType {
  String get label {
    switch (this) {
      case PlaceType.roaster: return 'Roaster';
      case PlaceType.cafe: return 'Café';
      case PlaceType.shop: return 'Shop';
    }
  }

  String get plural {
    switch (this) {
      case PlaceType.roaster: return 'Roasters';
      case PlaceType.cafe: return 'Cafés';
      case PlaceType.shop: return 'Shops';
    }
  }
}

class Place {
  final String id;
  final String name;
  final String city;
  final PlaceType type;
  final double lat;
  final double lon;
  final bool fictional;
  final String? serves;          // "Serves Morgon" — fictional places only
  final double? friendsRating;   // 1..5, fictional places only
  final double? everyoneRating;
  final int? ratingCount;

  const Place({
    required this.id,
    required this.name,
    required this.city,
    required this.type,
    required this.lat,
    required this.lon,
    this.fictional = false,
    this.serves,
    this.friendsRating,
    this.everyoneRating,
    this.ratingCount,
  });
}

// Pretend user location for the demo: central Göteborg
const double kUserLat = 57.7089;
const double kUserLon = 11.9746;

const List<Place> kPlaces = <Place>[
  // Real specialty roasters (from the pitch deck) — name, city and rough position only
  Place(id: 'swerl', name: 'Swerl', city: 'Falkenberg', type: PlaceType.roaster, lat: 56.905, lon: 12.491),
  Place(id: 'gringo', name: 'Gringo Nordic', city: 'Göteborg', type: PlaceType.roaster, lat: 57.672, lon: 12.005),
  Place(id: 'kafferaven', name: 'Kafferäven', city: 'Göteborg', type: PlaceType.roaster, lat: 57.698, lon: 11.948),
  Place(id: 'morgon', name: 'Morgon Coffee Roasters', city: 'Göteborg', type: PlaceType.roaster, lat: 57.715, lon: 11.968),
  Place(id: 'damatteo', name: 'Da Matteo', city: 'Göteborg', type: PlaceType.roaster, lat: 57.704, lon: 11.962),
  Place(id: 'drop', name: 'Drop Coffee', city: 'Stockholm', type: PlaceType.roaster, lat: 59.317, lon: 18.063),
  Place(id: 'standout', name: 'Standout Coffee', city: 'Stockholm', type: PlaceType.roaster, lat: 59.337, lon: 18.045),
  Place(id: 'johan', name: 'Johan & Nyström', city: 'Tullinge', type: PlaceType.roaster, lat: 59.205, lon: 17.903),
  Place(id: 'muttley', name: "Muttley & Jack's", city: 'Rindö, Vaxholm', type: PlaceType.roaster, lat: 59.398, lon: 18.405),
  Place(id: 'koppar', name: 'Kafferosteriet Koppar', city: 'Tyresö', type: PlaceType.roaster, lat: 59.244, lon: 18.228),
  Place(id: 'koppi', name: 'Koppi', city: 'Helsingborg', type: PlaceType.roaster, lat: 56.046, lon: 12.694),

  // Fictional cafés and shops (example data)
  Place(id: 'ljusgarden', name: 'Kafé Ljusgården', city: 'Göteborg', type: PlaceType.cafe, lat: 57.701, lon: 11.985,
      fictional: true, serves: 'Serves Morgon', friendsRating: 4.8, everyoneRating: 4.6, ratingCount: 212),
  Place(id: 'bonan', name: 'Bönan & Boken', city: 'Göteborg', type: PlaceType.shop, lat: 57.689, lon: 11.958,
      fictional: true, serves: 'Fresh bags from 6 roasters', friendsRating: 4.5, everyoneRating: 4.4, ratingCount: 87),
  Place(id: 'salto', name: 'Kaffebaren Saltö', city: 'Varberg', type: PlaceType.cafe, lat: 57.107, lon: 12.252,
      fictional: true, serves: 'Serves Swerl', friendsRating: 4.2, everyoneRating: 4.5, ratingCount: 64),
  Place(id: 'moellan', name: 'Kaffestugan Möllan', city: 'Malmö', type: PlaceType.cafe, lat: 55.591, lon: 13.008,
      fictional: true, serves: 'Serves Koppi', everyoneRating: 4.3, ratingCount: 141),
  Place(id: 'soder', name: 'Bryggeriet Söder', city: 'Stockholm', type: PlaceType.cafe, lat: 59.312, lon: 18.074,
      fictional: true, serves: 'Serves Drop Coffee', friendsRating: 4.7, everyoneRating: 4.7, ratingCount: 389),
  Place(id: 'kvarnen', name: 'Butik Kvarnen', city: 'Linköping', type: PlaceType.shop, lat: 58.411, lon: 15.621,
      fictional: true, serves: 'Beans, grinders & filters', everyoneRating: 4.1, ratingCount: 38),
];

// Great-circle distance in km
double distanceKm(double lat1, double lon1, double lat2, double lon2) {
  const double r = 6371;
  double rad(double d) => d * math.pi / 180;
  final double dLat = rad(lat2 - lat1);
  final double dLon = rad(lon2 - lon1);
  final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.sin(dLon / 2) * math.sin(dLon / 2);
  return 2 * r * math.asin(math.sqrt(a));
}

double distanceFromUser(Place p) => distanceKm(kUserLat, kUserLon, p.lat, p.lon);

// "350 m", "4.2 km", "396 km"
String formatDistance(double km) {
  if (km < 1) return '${(km * 1000 / 50).round() * 50} m';
  if (km < 10) return '${km.toStringAsFixed(1)} km';
  return '${km.round()} km';
}

// ---------------- Featured roaster (fictional partner) ----------------

class RoasterCoffee {
  final String name;
  final String originCountry;
  final String originRegion;
  final String process;
  final String variety;
  final String roastLevel;
  final List<String> notes;

  const RoasterCoffee({
    required this.name,
    required this.originCountry,
    required this.originRegion,
    required this.process,
    required this.variety,
    required this.roastLevel,
    required this.notes,
  });
}

class FeaturedRoaster {
  final String name;
  final String city;
  final String tagline;
  final List<String> article; // paragraphs
  final List<RoasterCoffee> coffees;
  final String recipeName;
  final double recipeDose;
  final double recipeWater;
  final double recipeTemp;
  final String recipeGrind;
  final int recipeTimeSecs;
  final List<BrewStep> recipeSteps;

  const FeaturedRoaster({
    required this.name,
    required this.city,
    required this.tagline,
    required this.article,
    required this.coffees,
    required this.recipeName,
    required this.recipeDose,
    required this.recipeWater,
    required this.recipeTemp,
    required this.recipeGrind,
    required this.recipeTimeSecs,
    required this.recipeSteps,
  });
}

const FeaturedRoaster kFeaturedRoaster = FeaturedRoaster(
  name: 'Nordlys Kafferosteri',
  city: 'Umeå, Sweden',
  tagline: 'Light roasts from the far north, roasted in small batches.',
  article: <String>[
    'Nordlys started in a garage outside Umeå in 2019, with a 5 kg roaster and a stubborn idea: '
        'that a light roast can be sweet, not sour. Today a team of four roasts twice a week and ships '
        'across Sweden.',
    'They buy directly from a handful of farms in Ethiopia, Kenya and Colombia, and roast each lot '
        'to taste rather than to a fixed profile. Every bag carries a roast date and a suggested rest time.',
    '“We want people to brew our coffee the way they like it — but if you ask us, give it ten days '
        'and brew it a little cooler than you think.”',
  ],
  coffees: <RoasterCoffee>[
    RoasterCoffee(
      name: 'Aricha',
      originCountry: 'Ethiopia',
      originRegion: 'Yirgacheffe',
      process: 'Natural',
      variety: 'Heirloom',
      roastLevel: 'Light',
      notes: <String>['blueberry', 'jasmine', 'cocoa nib'],
    ),
    RoasterCoffee(
      name: 'Gichathaini',
      originCountry: 'Kenya',
      originRegion: 'Nyeri',
      process: 'Washed',
      variety: 'SL28',
      roastLevel: 'Light',
      notes: <String>['blackcurrant', 'grapefruit', 'cane sugar'],
    ),
    RoasterCoffee(
      name: 'Finca El Mirador',
      originCountry: 'Colombia',
      originRegion: 'Huila',
      process: 'Washed',
      variety: 'Caturra',
      roastLevel: 'Medium-light',
      notes: <String>['red apple', 'caramel', 'milk chocolate'],
    ),
  ],
  recipeName: 'Nordlys V60',
  recipeDose: 15,
  recipeWater: 250,
  recipeTemp: 92,
  recipeGrind: 'Medium-fine',
  recipeTimeSecs: 180,
  recipeSteps: <BrewStep>[
    BrewStep(name: 'Bloom', durationSecs: 40, waterMl: 45),
    BrewStep(name: 'Pour 1', durationSecs: 30, waterMl: 105),
    BrewStep(name: 'Pour 2', durationSecs: 30, waterMl: 100),
  ],
);

// ---------------- Roaster insights panel (fictional partner) ----------------

class CoffeeInsight {
  final String coffee;       // "Aricha · Ethiopia"
  final int brews;
  final int users;
  final double avgScore;     // 1..5
  final int bestTempC;
  final String bestRestDays; // "10–14"
  final List<(double, double)> ratingByRest; // (days since roast, rating 1..5)
  final List<MapEntry<String, int>> methodShare; // percent
  final List<MapEntry<String, int>> topNotes;    // counted tags

  const CoffeeInsight({
    required this.coffee,
    required this.brews,
    required this.users,
    required this.avgScore,
    required this.bestTempC,
    required this.bestRestDays,
    required this.ratingByRest,
    required this.methodShare,
    required this.topNotes,
  });
}

// Deterministic example points: rating peaks around [peakDay] days off roast
List<(double, double)> _restCurve(int seed, double peakDay, int count) {
  final math.Random rng = math.Random(seed);
  return <(double, double)>[
    for (int i = 0; i < count; i++)
      () {
        final double day = 2 + rng.nextDouble() * 40;
        final double base = 4.6 - ((day - peakDay).abs() / 9).clamp(0.0, 2.6);
        final double score = (base + (rng.nextDouble() - 0.5) * 1.4).clamp(1.0, 5.0);
        return (day.roundToDouble(), score.roundToDouble());
      }(),
  ];
}

final List<CoffeeInsight> kCoffeeInsights = <CoffeeInsight>[
  CoffeeInsight(
    coffee: 'Aricha · Ethiopia',
    brews: 412,
    users: 87,
    avgScore: 4.3,
    bestTempC: 92,
    bestRestDays: '10–14',
    ratingByRest: _restCurve(7, 12, 46),
    methodShare: const <MapEntry<String, int>>[
      MapEntry<String, int>('V60', 58),
      MapEntry<String, int>('Aeropress', 21),
      MapEntry<String, int>('Espresso', 14),
      MapEntry<String, int>('Other', 7),
    ],
    topNotes: const <MapEntry<String, int>>[
      MapEntry<String, int>('Blueberry', 48),
      MapEntry<String, int>('Jasmine', 31),
      MapEntry<String, int>('Strawberry', 22),
      MapEntry<String, int>('Cocoa', 17),
      MapEntry<String, int>('Winey', 9),
    ],
  ),
  CoffeeInsight(
    coffee: 'Gichathaini · Kenya',
    brews: 268,
    users: 54,
    avgScore: 4.1,
    bestTempC: 94,
    bestRestDays: '14–21',
    ratingByRest: _restCurve(11, 17, 40),
    methodShare: const <MapEntry<String, int>>[
      MapEntry<String, int>('V60', 49),
      MapEntry<String, int>('Aeropress', 33),
      MapEntry<String, int>('Chemex', 12),
      MapEntry<String, int>('Other', 6),
    ],
    topNotes: const <MapEntry<String, int>>[
      MapEntry<String, int>('Blackcurrant', 39),
      MapEntry<String, int>('Grapefruit', 27),
      MapEntry<String, int>('Tomato', 12),
      MapEntry<String, int>('Cane sugar', 11),
    ],
  ),
  CoffeeInsight(
    coffee: 'El Mirador · Colombia',
    brews: 336,
    users: 71,
    avgScore: 3.9,
    bestTempC: 91,
    bestRestDays: '7–12',
    ratingByRest: _restCurve(23, 9, 42),
    methodShare: const <MapEntry<String, int>>[
      MapEntry<String, int>('Espresso', 52),
      MapEntry<String, int>('V60', 28),
      MapEntry<String, int>('Moka pot', 11),
      MapEntry<String, int>('Other', 9),
    ],
    topNotes: const <MapEntry<String, int>>[
      MapEntry<String, int>('Caramel', 44),
      MapEntry<String, int>('Red apple', 25),
      MapEntry<String, int>('Milk chocolate', 23),
      MapEntry<String, int>('Hazelnut', 8),
    ],
  ),
];

class PriceTier {
  final String name;
  final String price;
  final String? unit;
  final List<String> features;
  final bool highlighted;

  const PriceTier({required this.name, required this.price, this.unit, required this.features, this.highlighted = false});
}

const List<PriceTier> kRoasterTiers = <PriceTier>[
  PriceTier(name: 'Profile', price: 'Free', features: <String>['Your own roaster page', 'Coffees and recipes', 'Shown on the map']),
  PriceTier(
    name: 'Insights',
    price: '299–499',
    unit: 'kr / month',
    features: <String>['Insights panel per coffee', 'Ratings and taste notes', 'Best temperature and rest time'],
    highlighted: true,
  ),
  PriceTier(
    name: 'Insights Pro',
    price: '990–1 490',
    unit: 'kr / month',
    features: <String>['Trends over time', 'Compare with anonymous average', 'Roast curves per batch'],
  ),
  PriceTier(
    name: 'Featured',
    price: 'Per campaign',
    features: <String>['Featured placement in the app', 'Launch new coffees', 'Always marked as sponsored'],
  ),
];
