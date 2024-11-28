

import 'package:flutter/material.dart';
import 'db_manager.dart';
import 'food_item.dart';

class OrderFoodPage extends StatefulWidget {
  const OrderFoodPage({super.key});

  @override
  _OrderFoodPageState createState() => _OrderFoodPageState();
}

class _OrderFoodPageState extends State<OrderFoodPage> {
  late DBManager dbManager;
  List<FoodItem> foodItems = [];
  List<FoodItem> selectedItems = [];
  TextEditingController _targetCostController = TextEditingController();
  TextEditingController _queryDateController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  List<FoodItem> queriedOrderItems = [];

  @override
  void initState() {
    super.initState();
    dbManager = DBManager();
    _getFoodItems();
  }

  // Fetch all food items from the database
  Future<void> _getFoodItems() async {
    // Ensure the database is initialized before fetching food items
    await dbManager.initialize();
    foodItems = await dbManager.getFoodItems();
    setState(() {});
  }

  // Date picker function
  Future<void> _selectDate(BuildContext context) async {
    final DateTime picked = (await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    ))!;
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Add item to selected items list
  void _toggleSelection(FoodItem item) {
    setState(() {
      if (selectedItems.contains(item)) {
        selectedItems.remove(item);
      } else {
        selectedItems.add(item);
      }
    });
  }

  // Calculate the total cost of selected items
  double _calculateTotalCost() {
    return selectedItems.fold(0, (sum, item) => sum + item.price);
  }

  // Save the order plan to the database
  void _saveOrderPlan() async {
    if (_targetCostController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter a target cost")),
      );
      return;
    }

    double targetCost = double.parse(_targetCostController.text);
    double totalCost = _calculateTotalCost();

    // Check if the total cost exceeds the target cost
    if (totalCost > targetCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Total cost exceeds target cost")),
      );
    } else {
      // Save the order plan to the database
      await dbManager.saveOrderPlan(_selectedDate, selectedItems);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Order plan saved!")),
      );

      // Optionally, you can reset the selected items and target cost after saving
      setState(() {
        selectedItems = [];
        _targetCostController.clear();
      });
    }
  }

  // Query the database for the order plan by date
  void _queryOrderPlan() async {
    String queryDateText = _queryDateController.text;
    if (queryDateText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter a date")),
      );
      return;
    }

    // Try parsing the query date
    DateTime queryDate;
    try {
      queryDate = DateTime.parse(queryDateText);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Invalid date format. Use YYYY-MM-DD")),
      );
      return;
    }

    // Get the order plan from the database
    List<FoodItem> orderPlan = await dbManager.getOrderPlan(queryDate);

    setState(() {
      queriedOrderItems = orderPlan;
    });

    if (orderPlan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No order found for this date")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Food Ordering App")),
      body: Column(
        children: [
          // Target cost input field
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _targetCostController,
              decoration: const InputDecoration(labelText: "Target Cost"),
              keyboardType: TextInputType.number,
            ),
          ),
          // Date picker button
          TextButton(
            onPressed: () => _selectDate(context),
            child: Text("Select Date: ${_selectedDate.toLocal()}"),
          ),
          // List of food items to select from
          Expanded(
            child: foodItems.isEmpty
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: foodItems.length,
              itemBuilder: (context, index) {
                final foodItem = foodItems[index];
                return CheckboxListTile(
                  title: Text(foodItem.name), // Display food name
                  subtitle: Text('\$${foodItem.price.toStringAsFixed(2)}'),
                  value: selectedItems.contains(foodItem),
                  onChanged: (value) {
                    _toggleSelection(foodItem);
                  },
                );
              },
            ),
          ),
          // Total cost display
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Total Cost: \$${_calculateTotalCost().toStringAsFixed(2)}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: _saveOrderPlan,
            child: const Text("Save Order Plan"),
          ),
          // Query section to fetch order by date
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _queryDateController,
              decoration: const InputDecoration(labelText: "Enter Date (YYYY-MM-DD)"),
              keyboardType: TextInputType.datetime,
            ),
          ),
          ElevatedButton(
            onPressed: _queryOrderPlan,
            child: const Text("Query Order Plan"),
          ),
          // Display queried order plan if found
          Expanded(
            child: ListView.builder(
              itemCount: queriedOrderItems.length,
              itemBuilder: (context, index) {
                final foodItem = queriedOrderItems[index];
                return ListTile(
                  title: Text(foodItem.name),
                  subtitle: Text('\$${foodItem.price.toStringAsFixed(2)}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
