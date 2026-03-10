import 'package:dio/dio.dart';
import 'auth_service.dart';
import 'bag_service.dart';
import 'brew_service.dart';
import 'equipment_service.dart';

/// Bundles all API services into one object so that widgets only
/// need a single `services` parameter instead of a growing list.
class AppServices {
  final AuthService auth;
  final BrewService brews;
  final EquipmentService equipment;
  final BagService bags;

  const AppServices({
    required this.auth,
    required this.brews,
    required this.equipment,
    required this.bags,
  });

  /// Constructs all services from a single shared [Dio] instance.
  factory AppServices.fromDio(Dio dio) => AppServices(
        auth: AuthService(dio),
        brews: BrewService(dio),
        equipment: EquipmentService(dio),
        bags: BagService(dio),
      );
}
