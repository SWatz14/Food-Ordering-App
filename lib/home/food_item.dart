

class FoodItem {
  final int? id;
  final String name;
  final String description;
  final double price;

  FoodItem({this.id, required this.name, required this.description, required this.price});

  // Convert FoodItem to Map (used for database insert)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
    };
  }

  // Convert Map to FoodItem (used for database query)
  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      price: map['price'],
    );
  }
}

