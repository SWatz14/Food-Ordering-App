

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'food_item.dart';

class DBManager {
  static final DBManager _instance = DBManager._internal();
  factory DBManager() => _instance;
  late Database _database;

  DBManager._internal();

  // Initialize the database only once
  Future<void> initialize() async {
    if (_database != null && _database.isOpen) return;
    await _initializeDatabase();
  }

  // Initialize the database and create tables
  Future<void> _initializeDatabase() async {
    String path = join(await getDatabasesPath(), 'food_ordering.db');
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''CREATE TABLE food_items (
            id INTEGER PRIMARY KEY,
            name TEXT,
            description TEXT,
            price REAL
          )''');
        await db.execute('''CREATE TABLE order_plans (
            id INTEGER PRIMARY KEY,
            date TEXT,
            food_item_ids TEXT
          )''');
        await _insertDefaultFoodItems(db);
      },
    );
  }

  // Insert default food items into the database
  Future<void> _insertDefaultFoodItems(Database db) async {
    List<Map<String, dynamic>> foodItems = [
      {'name': 'Pizza', 'description': 'Cheese Pizza', 'price': 10.0},
      {'name': 'Burger', 'description': 'Beef Burger', 'price': 7.0},
      {'name': 'Pasta', 'description': 'Spaghetti with Marinara', 'price': 8.5},
      {'name': 'Sushi', 'description': 'California Rolls', 'price': 12.0},
      {'name': 'Tacos', 'description': 'Beef Tacos', 'price': 6.5},
      {'name': 'Steak', 'description': 'Grilled Steak', 'price': 20.0},
      {'name': 'Chicken Wings', 'description': 'Spicy Chicken Wings', 'price': 9.0},
      {'name': 'Salad', 'description': 'Caesar Salad', 'price': 5.5},
      {'name': 'Sandwich', 'description': 'Club Sandwich', 'price': 6.0},
      {'name': 'Fries', 'description': 'French Fries', 'price': 3.0},
      {'name': 'Ice Cream', 'description': 'Vanilla Ice Cream', 'price': 4.0},
      {'name': 'Cupcake', 'description': 'Chocolate Cupcake', 'price': 3.5},
      {'name': 'Pancakes', 'description': 'Stack of Pancakes', 'price': 7.0},
      {'name': 'Waffles', 'description': 'Belgian Waffles', 'price': 8.0},
      {'name': 'Bagel', 'description': 'Plain Bagel with Cream Cheese', 'price': 2.5},
      {'name': 'Smoothie', 'description': 'Mixed Berry Smoothie', 'price': 5.0},
      {'name': 'Coffee', 'description': 'Espresso Coffee', 'price': 2.0},
      {'name': 'Tea', 'description': 'Green Tea', 'price': 1.5},
      {'name': 'Juice', 'description': 'Fresh Orange Juice', 'price': 3.0},
      {'name': 'Chocolate Cake', 'description': 'Moist Chocolate Cake', 'price': 5.5},
    ];

    for (var foodItem in foodItems) {
      await db.insert('food_items', foodItem, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  // Fetch all food items from the database
  Future<List<FoodItem>> getFoodItems() async {
    await initialize(); // Ensure the database is initialized
    final db = await _database;
    var result = await db.query('food_items');
    return result.map((e) => FoodItem.fromMap(e)).toList();
  }

  // Save the order plan with the selected food items and date
  Future<void> saveOrderPlan(DateTime date, List<FoodItem> selectedItems) async {
    await initialize(); // Ensure the database is initialized
    String foodItemIds = selectedItems.map((item) => item.id.toString()).join(',');
    await _database.insert('order_plans', {
      'date': date.toIso8601String(),
      'food_item_ids': foodItemIds,
    });
  }

  // Get the order plan for a specific date
  Future<List<FoodItem>> getOrderPlan(DateTime date) async {
    await initialize(); // Ensure the database is initialized
    final List<Map<String, dynamic>> maps = await _database.query(
      'order_plans',
      where: 'date = ?',
      whereArgs: [date.toIso8601String()],
    );

    if (maps.isEmpty) return [];

    String foodItemIds = maps[0]['food_item_ids'];
    List<String> ids = foodItemIds.split(',');

    List<FoodItem> selectedItems = [];
    for (var id in ids) {
      final List<Map<String, dynamic>> foodItem = await _database.query(
        'food_items',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (foodItem.isNotEmpty) {
        selectedItems.add(FoodItem.fromMap(foodItem[0]));
      }
    }
    return selectedItems;
  }
}

