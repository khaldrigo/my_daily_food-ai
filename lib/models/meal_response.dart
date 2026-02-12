class MealResponse {
  final double kcal;
  final double proteina;
  final double carbo;
  final double gordura;

  MealResponse({
    required this.kcal,
    required this.proteina,
    required this.carbo,
    required this.gordura,
  });

  factory MealResponse.fromJson(Map<String, dynamic> json) {
    return MealResponse(
      // Usamos .toDouble() para garantir que não quebre se a IA mandar int
      kcal: (json['kcal'] ?? 0.0).toDouble(),
      proteina: (json['proteina'] ?? 0.0).toDouble(),
      carbo: (json['carbo'] ?? 0.0).toDouble(),
      gordura: (json['gordura'] ?? 0.0).toDouble(),
    );
  }
}
