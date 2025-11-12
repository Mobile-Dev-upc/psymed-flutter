// lib/services/medication_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/medication_model.dart';

class MedicationService {
  static const String baseUrl = 'https://psymed-backend-new.onrender.com/api/v1';

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

  // Crear un nuevo medicamento
  Future<Medication> createMedication(MedicationRequest request, String token) async {
    try {
      print('Creando medicamento: ${request.toJson()}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/pills'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(request.toJson()),
      );

      print('Create Response Status: ${response.statusCode}');
      print('Create Response Body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = _parseResponse(response);
        return Medication.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception('Token inválido o expirado');
      } else if (response.statusCode == 400) {
        final errorBody = _parseResponse(response);
        throw Exception('Error de validación: ${errorBody['message'] ?? 'Datos inválidos'}');
      } else {
        throw Exception('Error al crear medicamento. Status: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Failed host lookup')) {
        throw Exception('No se puede conectar al servidor.');
      }
      throw Exception('Error de conexión: $e');
    }
  }

  // Actualizar un medicamento
  Future<Medication> updateMedication(int medicationId, MedicationUpdateRequest request, String token) async {
    try {
      print('Actualizando medicamento ID: $medicationId');
      print('Datos: ${request.toJson()}');
      
      final response = await http.put(
        Uri.parse('$baseUrl/pills/$medicationId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(request.toJson()),
      );

      print('Update Response Status: ${response.statusCode}');
      print('Update Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = _parseResponse(response);
        return Medication.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception('Token inválido o expirado');
      } else if (response.statusCode == 404) {
        throw Exception('Medicamento no encontrado');
      } else if (response.statusCode == 400) {
        final errorBody = _parseResponse(response);
        throw Exception('Error de validación: ${errorBody['message'] ?? 'Datos inválidos'}');
      } else {
        throw Exception('Error al actualizar medicamento. Status: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Failed host lookup')) {
        throw Exception('No se puede conectar al servidor.');
      }
      throw Exception('Error de conexión: $e');
    }
  }

  // Eliminar un medicamento
  Future<void> deleteMedication(int medicationId, String token) async {
    try {
      print('Eliminando medicamento ID: $medicationId');
      
      final response = await http.delete(
        Uri.parse('$baseUrl/pills/$medicationId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Delete Response Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Eliminación exitosa
        return;
      } else if (response.statusCode == 401) {
        throw Exception('Token inválido o expirado');
      } else if (response.statusCode == 404) {
        throw Exception('Medicamento no encontrado');
      } else {
        throw Exception('Error al eliminar medicamento. Status: ${response.statusCode}');
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