class Category {
  final String id;
  final String name;
  final String? iconName;
  final int sortOrder;

  String get displayName {
    switch (name.toLowerCase()) {
      case 'all':
        return 'Все';
      case 'food':
        return 'Корма';
      case 'toys':
        return 'Игрушки';
      case 'healthcare':
        return 'Здоровье';
      case 'accessories':
        return 'Аксессуары';
      case 'grooming':
        return 'Груминг';
      case 'clothing':
        return 'Одежда';
      default:
        return name;
    }
  }

  Category({
    required this.id,
    required this.name,
    this.iconName,
    required this.sortOrder,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      iconName: json['iconName'] as String?,
      sortOrder: json['sortOrder'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconName': iconName,
      'sortOrder': sortOrder,
    };
  }
}
