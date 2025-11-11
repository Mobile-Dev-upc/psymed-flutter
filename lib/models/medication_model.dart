// lib/models/medication_model.dart
class Medication {
  final int id;
  final String name;
  final String description;
  final int patientId;
  final String interval;
  final String quantity;

  Medication({
    required this.id,
    required this.name,
    required this.description,
    required this.patientId,
    required this.interval,
    required this.quantity,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      patientId: json['patientId'],
      interval: json['interval'],
      quantity: json['quantity'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'patientId': patientId,
      'interval': interval,
      'quantity': quantity,
    };
  }
}

