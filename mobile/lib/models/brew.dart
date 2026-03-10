// Mirrors BrewResponse from Backend
// Derived fields (ratio, water_temp_f, brew_time etc are included - sent by backend)

class Brew {
  final int id;
  final int userId;
  final String? brewHash;
  final int? coffeeBagId;
  final DateTime brewDatetime;
  final int? grinderId;
  final String? grindSetting;
  final int? brewerId;
  final String? filterPaper;
  final double? coffeeGrams;
  final double? waterGrams;
  final double? waterTempC;
  final int? brewTimeSecs;
  final String? rating;
  final String? review;
  final String? notes;
  final DateTime createdAt;

  // Derived fields (computed by backend and sent in response)
  final double? ratio;
  final double? waterTempF;
  final String? brewTimeDisplay; // "MM:SS"

  const Brew({
    required this.id,
    required this.userId,
    this.brewHash,
    this.coffeeBagId,
    required this.brewDatetime,
    this.grinderId,
    this.grindSetting,
    this.brewerId,
    this.filterPaper,
    this.coffeeGrams,
    this.waterGrams,
    this.waterTempC,
    this.brewTimeSecs,
    this.rating,
    this.review,
    this.notes,
    required this.createdAt,
    this.ratio,
    this.waterTempF,
    this.brewTimeDisplay,
  });

  // Deserialize from JSON map
  factory Brew.fromJson(Map<String, dynamic> json) {
    return Brew(
      id:               json['id'] as int,
      userId:           json['user_id'] as int,
      brewHash:         json['brew_hash'] as String?,
      coffeeBagId:      json['coffee_bag_id'] as int?,
      brewDatetime:     DateTime.parse(json['brew_datetime'] as String),
      grinderId:        json['grinder_id'] as int?,
      grindSetting:     json['grind_setting'] as String?,
      brewerId:         json['brewer_id'] as int?,
      filterPaper:      json['filter_paper'] as String?,
      coffeeGrams:      (json['coffee_grams'] as num?)?.toDouble(),
      waterGrams:       (json['water_grams'] as num?)?.toDouble(),
      waterTempC:       (json['water_temp_c'] as num?)?.toDouble(),
      brewTimeSecs:     json['brew_time_secs'] as int?,
      rating:           json['rating'] as String?,
      review:           json['review'] as String?,
      notes:            json['notes'] as String?,
      createdAt:        DateTime.parse(json['created_at'] as String),
      ratio:            (json['ratio'] as num?)?.toDouble(),
      waterTempF:       (json['water_temp_f'] as num?)?.toDouble(),
      brewTimeDisplay:  json['brew_time_display'] as String?,
    );
  }

}
