import 'brew.dart';

// Mirrors Recipe from backend: saved once, picked when logging a brew
class Recipe {
  final int id;
  final String name;
  final String? brewType;   // 'v60' | 'aeropress' | 'espresso' ...
  final double? coffeeGrams;
  final double? waterGrams;
  final double? waterTempC;
  final int? brewTimeSecs;
  final List<BrewStep>? steps;
  final String? notes;
  final String? source;     // e.g. a roaster or another user
  final bool isDefault;

  const Recipe({
    required this.id,
    required this.name,
    this.brewType,
    this.coffeeGrams,
    this.waterGrams,
    this.waterTempC,
    this.brewTimeSecs,
    this.steps,
    this.notes,
    this.source,
    this.isDefault = false,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) => Recipe(
        id: json['id'] as int,
        name: json['name'] as String,
        brewType: json['brew_type'] as String?,
        coffeeGrams: (json['coffee_grams'] as num?)?.toDouble(),
        waterGrams: (json['water_grams'] as num?)?.toDouble(),
        waterTempC: (json['water_temp_c'] as num?)?.toDouble(),
        brewTimeSecs: json['brew_time_secs'] as int?,
        steps: (json['steps'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>()
            .map(BrewStep.fromJson)
            .toList(),
        notes: json['notes'] as String?,
        source: json['source'] as String?,
        isDefault: json['is_default'] as bool? ?? false,
      );

  double? get ratio =>
      (coffeeGrams != null && waterGrams != null && coffeeGrams! > 0) ? waterGrams! / coffeeGrams! : null;

  @override
  String toString() => name;
}
