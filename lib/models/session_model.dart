// lib/models/session_model.dart
class Session {
  final int id;
  final int patientId;
  final int professionalId;
  final DateTime appointmentDate;
  final int sessionTime;

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
      sessionTime: _toInt(json['sessionTime']),
    );
  }

  // Helper method para convertir de forma segura a int
  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.parse(value);
    throw Exception('Cannot convert $value to int');
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