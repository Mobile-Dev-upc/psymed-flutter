// lib/providers/professional_provider.dart
import 'package:flutter/material.dart';
import '../services/api_services.dart';
import '../models/user_model.dart';

class ProfessionalProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<PatientSummary> _patients = [];
  PatientProfile? _selectedPatient;
  bool _isLoading = false;
  String? _errorMessage;

  List<PatientSummary> get patients => _patients;
  PatientProfile? get selectedPatient => _selectedPatient;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Obtener la lista de pacientes de un profesional
  Future<bool> loadPatients(int professionalId, String token) async {
    print('ProfessionalProvider.loadPatients called');
    print('Professional ID: $professionalId');
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _patients = await _apiService.getPatientsByProfessional(professionalId, token);
      print('Pacientes cargados exitosamente: ${_patients.length}');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('ERROR en loadPatients: $e');
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Cargar los datos completos de un paciente específico
  Future<bool> loadPatientDetails(int patientId, String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedPatient = await _apiService.getPatientProfileById(patientId, token);
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

  // Actualizar un paciente
  Future<bool> updatePatient(int patientId, UpdatePatientProfileRequest request, String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.updatePatientProfile(patientId, request, token);
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

  // Eliminar un paciente
  Future<bool> deletePatient(int patientId, String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.deletePatientProfile(patientId, token);
      
      // Remover el paciente de la lista local
      _patients.removeWhere((patient) => patient.id == patientId);
      
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

  // Limpiar el paciente seleccionado
  void clearSelectedPatient() {
    _selectedPatient = null;
    notifyListeners();
  }

  // Limpiar todos los datos
  void clear() {
    _patients = [];
    _selectedPatient = null;
    _errorMessage = null;
    notifyListeners();
  }
}

