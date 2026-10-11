import 'package:flutter/foundation.dart';

import '../models/brew.dart';
import '../models/coffee_bag.dart';
import '../models/equipment.dart';
import '../models/recipe.dart';
import '../services/app_services.dart';

/// All of the user's data, loaded once after login and shared by every screen.
/// Screens rebuild with `ListenableBuilder(listenable: data, ...)`.
/// Mutations go through the API, then update the local lists and notify.
class AppData extends ChangeNotifier {
  final AppServices services;
  AppData(this.services);

  List<CoffeeBag> bags = <CoffeeBag>[];
  List<Brew> brews = <Brew>[]; // newest first
  List<Grinder> grinders = <Grinder>[];
  List<Brewer> brewers = <Brewer>[];
  List<Recipe> recipes = <Recipe>[];

  bool isLoading = false;
  bool isLoaded = false;
  Object? error;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final List<Object> r = await Future.wait<Object>(<Future<Object>>[
        services.bags.listBags(),
        services.brews.listBrews(),
        services.equipment.listGrinders(),
        services.equipment.listBrewers(),
        services.recipes.listRecipes(),
      ]);
      bags = r[0] as List<CoffeeBag>;
      brews = (r[1] as List<Brew>)..sort((Brew a, Brew b) => b.brewDatetime.compareTo(a.brewDatetime));
      grinders = r[2] as List<Grinder>;
      brewers = r[3] as List<Brewer>;
      recipes = r[4] as List<Recipe>;
      isLoaded = true;
    } catch (e) {
      error = e;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    bags = <CoffeeBag>[];
    brews = <Brew>[];
    grinders = <Grinder>[];
    brewers = <Brewer>[];
    recipes = <Recipe>[];
    isLoaded = false;
    notifyListeners();
  }

  // ---- Lookups ----

  CoffeeBag? bag(int? id) => _find(bags, id, (CoffeeBag b) => b.id);
  Grinder? grinder(int? id) => _find(grinders, id, (Grinder g) => g.id);
  Brewer? brewer(int? id) => _find(brewers, id, (Brewer b) => b.id);
  Recipe? recipe(int? id) => _find(recipes, id, (Recipe r) => r.id);

  static T? _find<T>(List<T> items, int? id, int Function(T) idOf) {
    if (id == null) return null;
    for (final T item in items) {
      if (idOf(item) == id) return item;
    }
    return null;
  }

  List<Brew> brewsForBag(int bagId) => brews.where((Brew b) => b.coffeeBagId == bagId).toList();

  Brew? get lastBrew => brews.isEmpty ? null : brews.first;

  Brew? lastBrewForBag(int bagId) {
    for (final Brew b in brews) {
      if (b.coffeeBagId == bagId) return b;
    }
    return null;
  }

  DateTime? lastBrewedAt(int bagId) => lastBrewForBag(bagId)?.brewDatetime;

  /// Opened bags, most recently brewed first — the bags you pick from when logging.
  List<CoffeeBag> get activeBags {
    final List<CoffeeBag> active = bags.where((CoffeeBag b) => b.status != 'finished').toList();
    active.sort((CoffeeBag a, CoffeeBag b) {
      final DateTime da = lastBrewedAt(a.id) ?? a.createdAt;
      final DateTime db = lastBrewedAt(b.id) ?? b.createdAt;
      // Unopened bags go last
      if ((a.status == 'unopened') != (b.status == 'unopened')) return a.status == 'unopened' ? 1 : -1;
      return db.compareTo(da);
    });
    return active;
  }

  Recipe? get defaultRecipe {
    for (final Recipe r in recipes) {
      if (r.isDefault) return r;
    }
    return recipes.isEmpty ? null : recipes.first;
  }

  int brewCountForGrinder(int id) => brews.where((Brew b) => b.grinderId == id).length;
  int brewCountForBrewer(int id) => brews.where((Brew b) => b.brewerId == id).length;

  // ---- Mutations ----

  Future<Brew> addBrew({
    int? coffeeBagId,
    int? brewerId,
    int? grinderId,
    int? recipeId,
    String? grindSetting,
    String? filterPaper,
    double? coffeeGrams,
    double? waterGrams,
    double? waterTempC,
    int? brewTimeSecs,
    List<BrewStep>? brewSteps,
    DateTime? brewDatetime,
    String? rating,
    String? review,
    String? notes,
  }) async {
    final Brew brew = await services.brews.createBrew(
      coffeeBagId: coffeeBagId,
      brewerId: brewerId,
      grinderId: grinderId,
      recipeId: recipeId,
      grindSetting: grindSetting,
      filterPaper: filterPaper,
      coffeeGrams: coffeeGrams,
      waterGrams: waterGrams,
      waterTempC: waterTempC,
      brewTimeSecs: brewTimeSecs,
      brewSteps: brewSteps,
      brewDatetime: brewDatetime,
      rating: rating,
      review: review,
      notes: notes,
    );
    brews = <Brew>[brew, ...brews]..sort((Brew a, Brew b) => b.brewDatetime.compareTo(a.brewDatetime));

    // First brew of an unopened bag opens it
    final CoffeeBag? b = bag(coffeeBagId);
    if (b != null && b.status == 'unopened') await updateBag(b, status: 'opened');

    notifyListeners();
    return brew;
  }

  Future<void> deleteBrew(Brew brew) async {
    await services.brews.deleteBrew(brew.id);
    brews = brews.where((Brew b) => b.id != brew.id).toList();
    notifyListeners();
  }

  void addBagLocal(CoffeeBag newBag) {
    bags = <CoffeeBag>[newBag, ...bags];
    notifyListeners();
  }

  Future<CoffeeBag> updateBag(CoffeeBag b, {String? status, bool? favorite, String? rating}) async {
    final CoffeeBag updated = await services.bags.updateBag(
      b.id,
      b.toJson(status: status, favorite: favorite, rating: rating),
    );
    bags = bags.map((CoffeeBag x) => x.id == updated.id ? updated : x).toList();
    notifyListeners();
    return updated;
  }

  void addGrinderLocal(Grinder g) {
    grinders = <Grinder>[...grinders, g];
    notifyListeners();
  }

  void addBrewerLocal(Brewer b) {
    brewers = <Brewer>[...brewers, b];
    notifyListeners();
  }

  void replaceGrinder(Grinder g) {
    grinders = grinders.map((Grinder x) => x.id == g.id ? g : x).toList();
    notifyListeners();
  }

  void replaceBrewer(Brewer b) {
    brewers = brewers.map((Brewer x) => x.id == b.id ? b : x).toList();
    notifyListeners();
  }

  void addRecipeLocal(Recipe r) {
    recipes = <Recipe>[
      ...recipes.map((Recipe x) => r.isDefault && x.isDefault ? _undefault(x) : x),
      r,
    ];
    notifyListeners();
  }

  void removeRecipeLocal(int id) {
    recipes = recipes.where((Recipe r) => r.id != id).toList();
    notifyListeners();
  }

  static Recipe _undefault(Recipe r) => Recipe(
        id: r.id,
        name: r.name,
        brewType: r.brewType,
        coffeeGrams: r.coffeeGrams,
        waterGrams: r.waterGrams,
        waterTempC: r.waterTempC,
        brewTimeSecs: r.brewTimeSecs,
        steps: r.steps,
        notes: r.notes,
        source: r.source,
      );
}
