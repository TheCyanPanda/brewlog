// Pre-filled values for the Log brew screen ("Brew again", suggestions, recipes).
// Any null field falls back to the screen's own smart defaults.
class BrewDraft {
  final int? bagId;
  final int? brewerId;
  final int? grinderId;
  final int? recipeId;
  final String? grindSetting;
  final double? coffeeGrams;
  final double? waterGrams;
  final double? waterTempC;
  final int? brewTimeSecs;
  final String? filterPaper;
  final String? note; // e.g. "Suggested: 2 °C cooler, slightly coarser"

  const BrewDraft({
    this.bagId,
    this.brewerId,
    this.grinderId,
    this.recipeId,
    this.grindSetting,
    this.coffeeGrams,
    this.waterGrams,
    this.waterTempC,
    this.brewTimeSecs,
    this.filterPaper,
    this.note,
  });
}
