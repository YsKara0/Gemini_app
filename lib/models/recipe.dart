class Recipe {
  final String name;
  final String ingredients;
  final String instructions;
  final String cuisine;

  Recipe({
    required this.name,
    required this.ingredients,
    required this.instructions,
    required this.cuisine,
  });

  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      name: map['name'] ?? '',
      ingredients: map['ingredients'] ?? '',
      instructions: map['instructions'] ?? '',
      cuisine: map['cuisine'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'ingredients': ingredients,
      'instructions': instructions,
      'cuisine': cuisine,
    };
  }
}
