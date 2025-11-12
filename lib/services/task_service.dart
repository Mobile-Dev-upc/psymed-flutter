// lib/services/task_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task_model.dart';
import 'api_services.dart';

class TaskService {
  dynamic _parseResponse(http.Response response) {
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

  // Get all tasks for a patient
  Future<List<Task>> getTasksByPatientId(int patientId, String token) async {
    try {
      print('Obteniendo tareas del paciente: $patientId');
      
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/patients/$patientId/tasks'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = _parseResponse(response);
        return data.map((json) => Task.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Token inválido o expirado');
      } else {
        throw Exception('Error al obtener tareas: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception en getTasksByPatientId: $e');
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Failed host lookup')) {
        throw Exception('No se puede conectar al servidor');
      }
      throw Exception('Error de conexión: $e');
    }
  }

  // Get tasks by session ID
  Future<List<Task>> getTasksBySessionId(int sessionId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/sessions/$sessionId/tasks'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = _parseResponse(response);
        return data.map((json) => Task.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener tareas de la sesión');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Mark task as complete
  Future<void> markTaskComplete(int sessionId, int taskId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/sessions/$sessionId/tasks/$taskId/complete'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Error al marcar tarea como completa');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Mark task as incomplete
  Future<void> markTaskIncomplete(int sessionId, int taskId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/sessions/$sessionId/tasks/$taskId/incomplete'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Error al marcar tarea como incompleta');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Create a new task
  Future<Task> createTask(
    int sessionId,
    String title,
    String description,
    String token,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/sessions/$sessionId/tasks'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'title': title,
          'description': description,
        }),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Task.fromJson(_parseResponse(response));
      } else {
        throw Exception('Error al crear tarea');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<Task> updateTask(
    int sessionId,
    int taskId,
    String title,
    String description,
    String token,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/sessions/$sessionId/tasks/$taskId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'title': title,
          'description': description,
        }),
      );

      if (response.statusCode == 200) {
        return Task.fromJson(_parseResponse(response));
      } else if (response.statusCode == 404) {
        throw Exception('La tarea no existe');
      } else {
        throw Exception('Error al actualizar tarea');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Delete a task
  Future<void> deleteTask(int sessionId, int taskId, String token) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/sessions/$sessionId/tasks/$taskId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Error al eliminar tarea');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}

