import 'package:mobile/models/brew.dart';
import 'package:mobile/models/coffee_bag.dart';
import 'package:mobile/models/equipment.dart';

int _nextId = 1000;

Brew brew({
  int? id,
  int? bagId,
  int? brewerId,
  String? grind,
  double? temp,
  double? dose = 15,
  double? water = 250,
  String? rating,
  DateTime? at,
}) {
  final DateTime when = at ?? DateTime(2026, 10, 1, 8);
  return Brew(
    id: id ?? _nextId++,
    userId: 1,
    coffeeBagId: bagId,
    brewerId: brewerId,
    brewDatetime: when,
    grindSetting: grind,
    waterTempC: temp,
    coffeeGrams: dose,
    waterGrams: water,
    ratio: (dose != null && water != null) ? water / dose : null,
    rating: rating,
    createdAt: when,
  );
}

CoffeeBag bag(int id, {String? process, String? roast, String? country, String status = 'opened', List<String>? notes, DateTime? roastDate}) =>
    CoffeeBag(
      id: id,
      userId: 1,
      roaster: 'Roaster $id',
      process: process,
      roastLevel: roast,
      originCountry: country,
      status: status,
      tasteNotes: notes,
      roastDate: roastDate,
      createdAt: DateTime(2026, 1, 1),
    );

Brewer brewer(int id, {String method = 'filter', String type = 'v60'}) => Brewer(
      id: id,
      userId: 1,
      name: 'Brewer $id',
      brewMethod: method,
      brewType: type,
      createdAt: DateTime(2026, 1, 1),
    );
