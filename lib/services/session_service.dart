// lib/services/session_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/session_model.dart';

class SessionService {
  static const String baseUrl = 'http://192.168.1.71:8080/api/v1';

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

  // Obtener todas las sesiones de un paciente
  Future<List<Session>> getPatientSessions(int patientId, String token) async {
    try {
      print('Obteniendo sesiones para paciente: $patientId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/patients/$patientId/sessions'),
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
        return data.map((json) => Session.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        // No hay sesiones, retornar lista vacía
        return [];
      } else if (response.statusCode == 401) {
        throw Exception('Token inválido o expirado');
      } else {
        final errorBody = _parseResponse(response);
        throw Exception('Error al obtener sesiones: ${errorBody['message'] ?? response.body}');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Failed host lookup')) {
        throw Exception('No se puede conectar al servidor.');
      }
      throw Exception('Error de conexión: $e');
    }
  }

  Future<Session> createSession({
    required int professionalId,
    required int patientId,
    required SessionCreateRequest request,
    required String token,
  }) async {
    try {
      print('Creando sesión para paciente: $patientId y profesional: $professionalId');

      final response = await http.post(
        Uri.parse('$baseUrl/professionals/$professionalId/patients/$patientId/sessions'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(request.toJson()),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: El servidor no respondió a tiempo');
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = _parseResponse(response);
        return Session.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception('Token inválido o expirado');
      } else if (response.statusCode == 400) {
        final errorBody = _parseResponse(response);
        throw Exception('Error de validación: ${errorBody['message'] ?? 'Datos inválidos'}');
      } else {
        throw Exception('Error al crear sesión. Status: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception('No se puede conectar al servidor.');
      }
      throw Exception('Error de conexión: $e');
    }
  }

  Future<Session> updateSession({
    required int professionalId,
    required int patientId,
    required int sessionId,
    required SessionUpdateRequest request,
    required String token,
  }) async {
    try {
      print('Actualizando sesión $sessionId para paciente: $patientId');

      final response = await http.put(
        Uri.parse('$baseUrl/professionals/$professionalId/patients/$patientId/sessions/$sessionId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(request.toJson()),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: El servidor no respondió a tiempo');
        },
      );

      if (response.statusCode == 200) {
        final data = _parseResponse(response);
        return Session.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception('Token inválido o expirado');
      } else if (response.statusCode == 404) {
        throw Exception('Sesión no encontrada');
      } else if (response.statusCode == 400) {
        final errorBody = _parseResponse(response);
        throw Exception('Error de validación: ${errorBody['message'] ?? 'Datos inválidos'}');
      } else {
        throw Exception('Error al actualizar sesión. Status: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception('No se puede conectar al servidor.');
      }
      throw Exception('Error de conexión: $e');
    }
  }

  Future<void> deleteSession({
    required int professionalId,
    required int patientId,
    required int sessionId,
    required String token,
  }) async {
    try {
      print('Eliminando sesión $sessionId para paciente: $patientId');

      final response = await http.delete(
        Uri.parse('$baseUrl/professionals/$professionalId/patients/$patientId/sessions/$sessionId'),
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

      if (response.statusCode == 200 ||
          response.statusCode == 204) {
        return;
      } else if (response.statusCode == 401) {
        throw Exception('Token inválido o expirado');
      } else if (response.statusCode == 404) {
        throw Exception('Sesión no encontrada');
      } else {
        throw Exception('Error al eliminar sesión. Status: ${response.statusCode}');
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