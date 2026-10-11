class CoffeeBag {
  final int id;
  final int userId;
  final String? bagHash;
  final String? roaster;
  final String? roasterOriginCity;
  final String? roasterOriginCountry;
  final String? originCountry;
  final String? originRegion;
  final String? roastLevel;
  final String? process;
  final String? variety;
  final List<String>? tasteNotes;
  final DateTime? harvestDate;
  final DateTime? roastDate;
  final String? batchId;
  final String status;   // unopened | opened | finished
  final bool favorite;
  final String? rating;  // the bag's own rating, separate from each brew
  final String? buyUrl;
  final DateTime createdAt;

  const CoffeeBag({
    required this.id,
    required this.userId,
    this.bagHash,
    this.roaster,
    this.roasterOriginCity,
    this.roasterOriginCountry,
    this.originCountry,
    this.originRegion,
    this.roastLevel,
    this.process,
    this.variety,
    this.tasteNotes,
    this.harvestDate,
    this.roastDate,
    this.batchId,
    this.status = 'opened',
    this.favorite = false,
    this.rating,
    this.buyUrl,
    required this.createdAt,
  });

  factory CoffeeBag.fromJson(Map<String, dynamic> json) {
    return CoffeeBag(
      id:            json['id'] as int,
      userId:        json['user_id'] as int,
      bagHash:       json['bag_hash'] as String?,
      roaster:       json['roaster'] as String?,
      roasterOriginCity:    json['roaster_origin_city'] as String?,
      roasterOriginCountry: json['roaster_origin_country'] as String?,
      originCountry: json['origin_country'] as String?,
      originRegion:  json['origin_region'] as String?,
      roastLevel:    json['roast_level'] as String?,
      process:       json['process'] as String?,
      variety:       json['variety'] as String?,
      tasteNotes:    (json['taste_notes'] as List<dynamic>?)
          ?.cast<String>(),
      harvestDate:   _date(json['harvest_date']),
      roastDate:     _date(json['roast_date']),
      batchId:       json['batch_id'] as String?,
      status:        json['status'] as String? ?? 'opened',
      favorite:      json['favorite'] as bool? ?? false,
      rating:        json['rating'] as String?,
      buyUrl:        json['buy_url'] as String?,
      createdAt:     DateTime.parse(json['created_at'] as String),
    );
  }

  static DateTime? _date(Object? v) => v == null ? null : DateTime.parse(v as String);

  // Body for PUT /bags/:id — the full bag, with optional overrides
  Map<String, dynamic> toJson({String? status, bool? favorite, String? rating, bool clearRating = false}) =>
      <String, dynamic>{
        'roaster': roaster,
        'roaster_origin_city': roasterOriginCity,
        'roaster_origin_country': roasterOriginCountry,
        'origin_country': originCountry,
        'origin_region': originRegion,
        'roast_level': roastLevel,
        'variety': variety,
        'process': process,
        'taste_notes': tasteNotes,
        'harvest_date': _dateStr(harvestDate),
        'roast_date': _dateStr(roastDate),
        'batch_id': batchId,
        'status': status ?? this.status,
        'favorite': favorite ?? this.favorite,
        'rating': clearRating ? null : (rating ?? this.rating),
        'buy_url': buyUrl,
      };

  static String? _dateStr(DateTime? d) => d?.toIso8601String().substring(0, 10);

  // "Ethiopia · Yirgacheffe", or whatever part is known
  String get originLabel =>
      <String?>[originCountry, originRegion].whereType<String>().join(' · ').ifEmpty(roaster ?? 'Unknown origin');

  // Days since roast today (null if no roast date)
  int? get daysSinceRoast => roastDate == null ? null : DateTime.now().difference(roastDate!).inDays;

  // Display label for dropdowns: "MCR-0042 · Morgon" or just the hash
  String get displayName {
    if (bagHash != null && roaster != null) return '$bagHash · $roaster';
    if (bagHash != null) return bagHash!;
    if (roaster != null) return roaster!;
    return 'Bag #$id';
  }

  @override
  String toString() => displayName;
}

extension _IfEmpty on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
