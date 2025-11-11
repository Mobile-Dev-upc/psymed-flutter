// lib/services/analytics_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/mood_state_model.dart';
import '../models/biological_functions_model.dart';
import 'api_services.dart';

class AnalyticsService {
  // Get mood analytics
  Future<MoodAnalytic> getMoodAnalytics(
    int patientId,
    String year,
    String month,
    String token,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/mood-state-analytics?patientId=$patientId&year=$year&month=$month'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return MoodAnalytic.fromJson(json.decode(response.body));
      } else {
        throw Exception('Error al obtener análisis de estado de ánimo');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Get biological analytics
  Future<BiologicalAnalytic> getBiologicalAnalytics(
    int patientId,
    String year,
    String month,
    String token,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/biological-functions-analytics?patientId=$patientId&year=$year&month=$month'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return BiologicalAnalytic.fromJson(json.decode(response.body));
      } else {
        throw Exception('Error al obtener análisis biológico');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Get all mood states for a patient
  Future<List<MoodState>> getMoodStates(int patientId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/mood-states?patientId=$patientId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => MoodState.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener estados de ánimo');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Get all biological functions for a patient
  Future<List<BiologicalFunctions>> getBiologicalFunctions(
    int patientId,
    String token,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/biological-functions?patientId=$patientId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => BiologicalFunctions.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener funciones biológicas');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Create mood state
  Future<MoodState> createMoodState(
    int patientId,
    int mood,
    String token,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/mood-states'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'idPatient': patientId,
          'mood': mood,
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return MoodState.fromJson(json.decode(response.body));
      } else {
        throw Exception('Error al crear estado de ánimo');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Create biological function entry
  Future<BiologicalFunctions> createBiologicalFunction(
    int patientId,
    int hunger,
    int hydration,
    int sleep,
    int energy,
    String token,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/biological-functions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'idPatient': patientId,
          'hunger': hunger,
          'hydration': hydration,
          'sleep': sleep,
          'energy': energy,
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return BiologicalFunctions.fromJson(json.decode(response.body));
      } else {
        throw Exception('Error al crear registro biológico');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}

