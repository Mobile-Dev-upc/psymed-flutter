// lib/providers/session_provider.dart
import 'package:flutter/material.dart';
import '../models/session_model.dart';
import '../services/session_service.dart';

class SessionProvider with ChangeNotifier {
  final SessionService _sessionService = SessionService();
  
  List<Session> _sessions = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Session> get sessions => _sessions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasSessions => _sessions.isNotEmpty;

  // Obtener solo las sesiones futuras
  List<Session> get futureSessions {
    return _sessions.where((session) => session.isFuture).toList()
      ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));
  }

  // Obtener solo las sesiones pasadas
  List<Session> get pastSessions {
    return _sessions.where((session) => !session.isFuture).toList()
      ..sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));
  }

  // Obtener la próxima sesión
  Session? get nextSession {
    final future = futureSessions;
    return future.isEmpty ? null : future.first;
  }

  // Cargar sesiones del paciente
  Future<bool> loadPatientSessions(int patientId, String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _sessions = await _sessionService.getPatientSessions(patientId, token);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Limpiar sesiones (al cerrar sesión)
  void clearSessions() {
    _sessions = [];
    _errorMessage = null;
    notifyListeners();
  }
}