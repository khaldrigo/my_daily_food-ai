class FoodItem {
  String name;
  double grams;

  FoodItem({required this.name, required this.grams});

  @override
  String toString() => "$grams g de $name";
}