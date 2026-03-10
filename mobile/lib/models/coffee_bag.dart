class CoffeeBag {
  final int id;
  final int userId;
  final String? bagHash;
  final String? roaster;
  final String? originCountry;
  final String? originRegion;
  final String? roastLevel;
  final String? process;
  final String? variety;
  final List<String>? tasteNotes;
  final DateTime? roastDate;
  final DateTime createdAt;

  const CoffeeBag({
    required this.id,
    required this.userId,
    this.bagHash,
    this.roaster,
    this.originCountry,
    this.originRegion,
    this.roastLevel,
    this.process,
    this.variety,
    this.tasteNotes,
    this.roastDate,
    required this.createdAt,
  });

  factory CoffeeBag.fromJson(Map<String, dynamic> json) {
    return CoffeeBag(
      id:            json['id'] as int,
      userId:        json['user_id'] as int,
      bagHash:       json['bag_hash'] as String?,
      roaster:       json['roaster'] as String?,
      originCountry: json['origin_country'] as String?,
      originRegion:  json['origin_region'] as String?,
      roastLevel:    json['roast_level'] as String?,
      process:       json['process'] as String?,
      variety:       json['variety'] as String?,
      tasteNotes:    (json['taste_notes'] as List<dynamic>?)
          ?.cast<String>(),
      roastDate:     json['roast_date'] != null
          ? DateTime.parse(json['roast_date'] as String)
          : null,
      createdAt:     DateTime.parse(json['created_at'] as String),
    );
  }

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
