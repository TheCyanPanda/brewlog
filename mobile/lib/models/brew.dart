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
  final int? recipeId;
  final String? filterPaper;
  final double? coffeeGrams;
  final double? waterGrams;
  final double? waterTempC;
  final int? brewTimeSecs;
  final List<BrewStep>? brewSteps;
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
    this.recipeId,
    this.filterPaper,
    this.coffeeGrams,
    this.waterGrams,
    this.waterTempC,
    this.brewTimeSecs,
    this.brewSteps,
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
      brewDatetime:     DateTime.parse(json['brew_datetime'] as String).toLocal(),
      grinderId:        json['grinder_id'] as int?,
      grindSetting:     json['grind_setting'] as String?,
      brewerId:         json['brewer_id'] as int?,
      recipeId:         json['recipe_id'] as int?,
      filterPaper:      json['filter_paper'] as String?,
      coffeeGrams:      (json['coffee_grams'] as num?)?.toDouble(),
      waterGrams:       (json['water_grams'] as num?)?.toDouble(),
      waterTempC:       (json['water_temp_c'] as num?)?.toDouble(),
      brewTimeSecs:     json['brew_time_secs'] as int?,
      brewSteps:        (json['brew_steps'] as List<dynamic>?)
          ?.cast<Map<String, dynamic>>()
          .map(BrewStep.fromJson)
          .toList(),
      rating:           json['rating'] as String?,
      review:           json['review'] as String?,
      notes:            json['notes'] as String?,
      createdAt:        DateTime.parse(json['created_at'] as String).toLocal(),
      ratio:            (json['ratio'] as num?)?.toDouble(),
      waterTempF:       (json['water_temp_f'] as num?)?.toDouble(),
      brewTimeDisplay:  json['brew_time_display'] as String?,
    );
  }

  // Grind setting as a number, when the grinder uses numeric settings ("4.5")
  double? get grindValue => grindSetting == null ? null : double.tryParse(grindSetting!);
}

// One step of a recipe or brew: {"name":"Bloom","duration_secs":45,"water_ml":50}
class BrewStep {
  final String name;
  final int? durationSecs;
  final double? waterMl;

  const BrewStep({required this.name, this.durationSecs, this.waterMl});

  factory BrewStep.fromJson(Map<String, dynamic> json) => BrewStep(
        name: json['name'] as String? ?? '',
        durationSecs: json['duration_secs'] as int?,
        waterMl: (json['water_ml'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'duration_secs': ?durationSecs,
        'water_ml': ?waterMl,
      };
}
