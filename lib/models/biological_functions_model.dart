// lib/models/biological_functions_model.dart

class BiologicalFunctions {
  final int id;
  final int hunger;
  final int hydration;
  final int sleep;
  final int energy;
  final int idPatient;
  final DateTime? date;

  BiologicalFunctions({
    required this.id,
    required this.hunger,
    required this.hydration,
    required this.sleep,
    required this.energy,
    required this.idPatient,
    this.date,
  });

  factory BiologicalFunctions.fromJson(Map<String, dynamic> json) {
    return BiologicalFunctions(
      id: json['id'] ?? 0,
      hunger: json['hunger'] ?? 0,
      hydration: json['hydration'] ?? 0,
      sleep: json['sleep'] ?? 0,
      energy: json['energy'] ?? 0,
      idPatient: json['idPatient'] ?? 0,
      date: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'].toString())
          : (json['date'] != null 
              ? DateTime.parse(json['date'].toString())
              : (json['recordDate'] != null 
                  ? DateTime.parse(json['recordDate'].toString())
                  : null)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hunger': hunger,
      'hydration': hydration,
      'sleep': sleep,
      'energy': energy,
      'idPatient': idPatient,
      'date': date?.toIso8601String(),
    };
  }
}

class BiologicalAnalytic {
  final String idPatient;
  final String month;
  final String year;
  final double hungerAverage;
  final double sleepAverage;
  final double energyAverage;
  final double hydrationAverage;

  BiologicalAnalytic({
    required this.idPatient,
    required this.month,
    required this.year,
    required this.hungerAverage,
    required this.sleepAverage,
    required this.energyAverage,
    required this.hydrationAverage,
  });

  factory BiologicalAnalytic.fromJson(Map<String, dynamic> json) {
    return BiologicalAnalytic(
      idPatient: json['idPatient']?.toString() ?? '0',
      month: json['month']?.toString() ?? '0',
      year: json['year']?.toString() ?? '0',
      hungerAverage: double.tryParse(json['hungerAverage']?.toString() ?? '0') ?? 0.0,
      sleepAverage: double.tryParse(json['sleepAverage']?.toString() ?? '0') ?? 0.0,
      energyAverage: double.tryParse(json['energyAverage']?.toString() ?? '0') ?? 0.0,
      hydrationAverage: double.tryParse(json['hydrationAverage']?.toString() ?? '0') ?? 0.0,
    );
  }
}

