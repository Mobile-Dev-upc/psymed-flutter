// lib/providers/patient_report_provider.dart
import 'package:flutter/material.dart';
import '../models/patient_report_model.dart';
import '../services/patient_report_service.dart';

class PatientReportProvider with ChangeNotifier {
  final PatientReportService _reportService = PatientReportService();

  List<MoodState> _moodStates = [];
  List<BiologicalFunction> _biologicalFunctions = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  DateTime? _lastReportDate;

  List<MoodState> get moodStates => _moodStates;
  List<BiologicalFunction> get biologicalFunctions => _biologicalFunctions;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  // Cargar reportes del día
  Future<bool> loadTodayReports(int patientId, String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _moodStates = await _reportService.getMoodStates(patientId, token);
      _biologicalFunctions = await _reportService.getBiologicalFunctions(patientId, token);
      
      // Actualizar fecha del último reporte si hay datos
      if (_moodStates.isNotEmpty) {
        _lastReportDate = DateTime.now();
      }
      
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

  // Guardar reporte completo
  Future<bool> saveReport({
    required int patientId,
    required String token,
    required int moodStatus,
    required int hunger,
    required int hydration,
    required int sleep,
    required int energy,
  }) async {
    // Validar que no se haya registrado hoy
    if (hasReportedToday()) {
      _errorMessage = 'Ya has registrado tu estado de ánimo hoy';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Guardar estado de ánimo
      final moodRequest = MoodStateRequest(status: moodStatus);
      await _reportService.createMoodState(patientId, moodRequest, token);

      // Guardar funciones biológicas
      final bioRequest = BiologicalFunctionRequest(
        hunger: hunger,
        hydration: hydration,
        sleep: sleep,
        energy: energy,
      );
      await _reportService.createBiologicalFunction(patientId, bioRequest, token);

      // Actualizar fecha del último reporte
      _lastReportDate = DateTime.now();

      // Recargar datos
      await loadTodayReports(patientId, token);

      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  // Verificar si ya se registró hoy
  bool hasReportedToday() {
    if (_lastReportDate == null) return false;
    
    final now = DateTime.now();
    return _lastReportDate!.year == now.year &&
           _lastReportDate!.month == now.month &&
           _lastReportDate!.day == now.day;
  }

  // Limpiar reportes (al cerrar sesión)
  void clearReports() {
    _moodStates = [];
    _biologicalFunctions = [];
    _errorMessage = null;
    _lastReportDate = null;
    notifyListeners();
  }
}