// lib/models/patient_report_model.dart
class MoodState {
  final int id;
  final int status;

  MoodState({
    required this.id,
    required this.status,
  });

  factory MoodState.fromJson(Map<String, dynamic> json) {
    return MoodState(
      id: json['id'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
    };
  }
}

class MoodStateRequest {
  final int status;

  MoodStateRequest({required this.status});

  Map<String, dynamic> toJson() {
    return {
      'status': status,
    };
  }
}

class BiologicalFunction {
  final int id;
  final int hunger;
  final int hydration;
  final int sleep;
  final int energy;

  BiologicalFunction({
    required this.id,
    required this.hunger,
    required this.hydration,
    required this.sleep,
    required this.energy,
  });

  factory BiologicalFunction.fromJson(Map<String, dynamic> json) {
    return BiologicalFunction(
      id: json['id'],
      hunger: json['hunger'],
      hydration: json['hydration'],
      sleep: json['sleep'],
      energy: json['energy'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hunger': hunger,
      'hydration': hydration,
      'sleep': sleep,
      'energy': energy,
    };
  }
}

class BiologicalFunctionRequest {
  final int hunger;
  final int hydration;
  final int sleep;
  final int energy;

  BiologicalFunctionRequest({
    required this.hunger,
    required this.hydration,
    required this.sleep,
    required this.energy,
  });

  Map<String, dynamic> toJson() {
    return {
      'hunger': hunger,
      'hydration': hydration,
      'sleep': sleep,
      'energy': energy,
    };
  }
}