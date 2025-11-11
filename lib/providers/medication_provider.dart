// lib/providers/medication_provider.dart
import 'package:flutter/material.dart';
import '../models/medication_model.dart';
import '../services/medication_service.dart';

class MedicationProvider with ChangeNotifier {
  final MedicationService _medicationService = MedicationService();
  
  List<Medication> _medications = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Medication> get medications => _medications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasMedications => _medications.isNotEmpty;

  // Cargar medicamentos del paciente
  Future<bool> loadMedicationsByPatient(int patientId, String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _medications = await _medicationService.getMedicationsByPatient(patientId, token);
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

  // Limpiar medicamentos (al cerrar sesión)
  void clearMedications() {
    _medications = [];
    _errorMessage = null;
    notifyListeners();
  }
}