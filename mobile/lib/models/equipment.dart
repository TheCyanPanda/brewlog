class Grinder {
  final int id;
  final int userId;
  final String name;
  final String? notes;
  final DateTime createdAt;

  const Grinder({
    required this.id,
    required this.userId,
    required this.name,
    this.notes,
    required this.createdAt,
  });

  factory Grinder.fromJson(Map<String, dynamic> json) {
    return Grinder(
      id: json["id"] as int,
      userId: json["user_id"] as int,
      name: json["name"] as String,
      notes: json["notes"] as String?,
      createdAt: DateTime.parse(json["created_at"] as String),
    );
  }

  // Used by DropDownButton to display the item
  @override
  String toString() => name;
}


class Brewer {
  final int id;
  final int userId;
  final String name;
  final String brewMethod; // 'filter' 'espresso' etc
  final String? brewType; // 'v60', 'chemex' etc
  final String? brand;
  final String? model;
  final String? notes;
  final DateTime createdAt;

  const Brewer({
    required this.id,
    required this.userId,
    required this.name,
    required this.brewMethod,
    this.brewType,
    this.brand,
    this.model,
    this.notes,
    required this.createdAt
  });

  factory Brewer.fromJson(Map<String, dynamic> json) {
    return Brewer(
        id: json["id"] as int,
        userId: json["user_id"] as int,
        name: json["name"] as String,
        brewMethod: json["brew_method"] as String,
        brewType: json["brew_type"] as String?,
        brand: json["brand"] as String?,
        model: json["model"] as String?,
        notes: json["notes"] as String?,
        createdAt: DateTime.parse(json["created_at"] as String),
    );
  }

  @override
  String toString() => name;

}



