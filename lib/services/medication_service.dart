// lib/services/medication_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/medication_model.dart';

class MedicationService {
  static const String baseUrl = 'http://192.168.1.71:8080/api/v1';

  // Helper para parsear respuestas
  dynamic _parseResponse(http.Response response) {
    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.body.isEmpty) {
      throw Exception('El servidor no retornó datos. Status: ${response.statusCode}');
    }

    if (response.body.trim().startsWith('<')) {
      throw Exception('El servidor respondió con HTML en lugar de JSON.');
    }

    try {
      return json.decode(response.body);
    } catch (e) {
      throw Exception('Error al parsear JSON: $e');
    }
  }

  // Obtener todos los medicamentos de un paciente
  Future<List<Medication>> getMedicationsByPatient(int patientId, String token) async {
    try {
      print('Obteniendo medicamentos para paciente: $patientId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/pills/patient/$patientId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: El servidor no respondió a tiempo');
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = _parseResponse(response);
        return data.map((json) => Medication.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        // No hay medicamentos, retornar lista vacía
        return [];
      } else if (response.statusCode == 401) {
        throw Exception('Token inválido o expirado');
      } else {
        final errorBody = _parseResponse(response);
        throw Exception('Error al obtener medicamentos: ${errorBody['message'] ?? response.body}');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Failed host lookup')) {
        throw Exception('No se puede conectar al servidor.');
      }
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener todos los medicamentos (admin)
  Future<List<Medication>> getAllMedications(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/pills'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: El servidor no respondió a tiempo');
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = _parseResponse(response);
        return data.map((json) => Medication.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        return [];
      } else if (response.statusCode == 401) {
        throw Exception('Token inválido o expirado');
      } else {
        throw Exception('Error al obtener medicamentos');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Failed host lookup')) {
        throw Exception('No se puede conectar al servidor.');
      }
      throw Exception('Error de conexión: $e');
    }
  }
}