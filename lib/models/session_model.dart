// lib/models/session_model.dart
class Session {
  final int id;
  final int patientId;
  final int professionalId;
  final DateTime appointmentDate;
  final double sessionTime; // Duration in HOURS

  Session({
    required this.id,
    required this.patientId,
    required this.professionalId,
    required this.appointmentDate,
    required this.sessionTime,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: _toInt(json['id']),
      patientId: _toInt(json['patientId']),
      professionalId: _toInt(json['professionalId']),
      appointmentDate: DateTime.parse(json['appointmentDate']),
      sessionTime: _toDouble(json['sessionTime']),
    );
  }

  // Helper method para convertir de forma segura a int
  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.parse(value);
    throw Exception('Cannot convert $value to int');
  }

  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.parse(value);
    throw Exception('Cannot convert $value to double');
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'professionalId': professionalId,
      'appointmentDate': appointmentDate.toIso8601String(),
      'sessionTime': sessionTime,
    };
  }

  // Helper para verificar si la sesión es futura
  bool get isFuture => appointmentDate.isAfter(DateTime.now());
  
  // Helper para verificar si la sesión es hoy
  bool get isToday {
    final now = DateTime.now();
    return appointmentDate.year == now.year &&
           appointmentDate.month == now.month &&
           appointmentDate.day == now.day;
  }

  // Helper para obtener el tiempo restante
  Duration get timeUntilSession => appointmentDate.difference(DateTime.now());
}

class SessionCreateRequest {
  final DateTime appointmentDate;
  final double sessionTime;

  SessionCreateRequest({
    required this.appointmentDate,
    required this.sessionTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'appointmentDate': appointmentDate.toIso8601String(),
      'sessionTime': sessionTime,
    };
  }
}

class SessionUpdateRequest {
  final DateTime appointmentDate;
  final double sessionTime;

  SessionUpdateRequest({
    required this.appointmentDate,
    required this.sessionTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'appointmentDate': appointmentDate.toIso8601String(),
      'sessionTime': sessionTime,
    };
  }
}