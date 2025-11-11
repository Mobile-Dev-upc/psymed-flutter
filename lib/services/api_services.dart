// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class ApiService {
  // IMPORTANTE: Cambia esta URL según tu entorno
  // Para emulador Android usa: http://10.0.2.2:8080/api/v1
  // Para emulador iOS usa: http://localhost:8080/api/v1
  // Para dispositivo físico usa tu IP local: http://192.168.x.x:8080/api/v1
  static const String baseUrl = 'http://192.168.1.71:8080/api/v1';
  
  // Helper method para manejar respuestas y errores
  Map<String, dynamic> _parseResponse(http.Response response) {
    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');
    
    // Verificar si la respuesta está vacía
    if (response.body.isEmpty) {
      throw Exception('El servidor no retornó datos. Status: ${response.statusCode}');
    }
    
    // Verificar si la respuesta es HTML (error común)
    if (response.body.trim().startsWith('<')) {
      throw Exception('El servidor respondió con HTML en lugar de JSON. Verifica la URL del backend.');
    }
    
    try {
      return json.decode(response.body);
    } catch (e) {
      throw Exception('Error al parsear JSON: $e. Body: ${response.body}');
    }
  }
  
  // Sign Up - Registro de usuario
  Future<UserResponse> signUp(SignUpRequest request) async {
    try {
      print('Intentando registro con URL: $baseUrl/authentication/sign-up');
      print('Datos: ${json.encode(request.toJson())}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/authentication/sign-up'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(request.toJson()),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: El servidor no respondió a tiempo');
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return UserResponse.fromJson(_parseResponse(response));
      } else {
        if (response.body.isNotEmpty) {
          final errorBody = _parseResponse(response);
          throw Exception('Error al registrar usuario: ${errorBody['message'] ?? response.body}');
        } else {
          throw Exception('Error al registrar usuario. Status: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Failed host lookup')) {
        throw Exception('No se puede conectar al servidor. Verifica la URL y que el backend esté ejecutándose.');
      }
      throw Exception('Error de conexión: $e');
    }
  }
  
  // Sign In - Inicio de sesión
  Future<AuthResponse> signIn(SignInRequest request) async {
    try {
      print('Intentando login con URL: $baseUrl/authentication/sign-in');
      print('Datos: ${json.encode(request.toJson())}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/authentication/sign-in'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(request.toJson()),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: El servidor no respondió a tiempo');
        },
      );
      
      if (response.statusCode == 200) {
        return AuthResponse.fromJson(_parseResponse(response));
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('Credenciales inválidas');
      } else {
        final errorBody = _parseResponse(response);
        throw Exception('Error al iniciar sesión: ${errorBody['message'] ?? response.body}');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Failed host lookup')) {
        throw Exception('No se puede conectar al servidor. Verifica la URL y que el backend esté ejecutándose.');
      }
      throw Exception('Error de conexión: $e');
    }
  }
  
  // Crear perfil de paciente
  Future<PatientProfile> createPatientProfile(PatientProfileRequest request) async {
    try {
      print('Creando perfil de paciente con URL: $baseUrl/patient-profiles');
      print('Datos: ${json.encode(request.toJson())}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/patient-profiles'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(request.toJson()),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: El servidor no respondió a tiempo');
        },
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return PatientProfile.fromJson(_parseResponse(response));
      } else {
        if (response.body.isNotEmpty) {
          final errorBody = _parseResponse(response);
          throw Exception('Error al crear perfil: ${errorBody['message'] ?? response.body}');
        } else {
          throw Exception('Error al crear perfil. Status: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Exception en createPatientProfile: $e');
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Failed host lookup')) {
        throw Exception('No se puede conectar al servidor. Verifica la URL y que el backend esté ejecutándose.');
      }
      throw Exception('Error de conexión: $e');
    }
  }
  
  // Obtener cuenta por ID
  Future<UserResponse> getAccount(int accountId, String token) async {
    try {
      print('Obteniendo cuenta con URL: $baseUrl/accounts/$accountId');
      print('Token: $token');
      
      final response = await http.get(
        Uri.parse('$baseUrl/accounts/$accountId'),
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
        return UserResponse.fromJson(_parseResponse(response));
      } else if (response.statusCode == 401) {
        throw Exception('Token inválido o expirado');
      } else {
        final errorBody = _parseResponse(response);
        throw Exception('Error al obtener cuenta: ${errorBody['message'] ?? response.body}');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Failed host lookup')) {
        throw Exception('No se puede conectar al servidor. Verifica la URL y que el backend esté ejecutándose.');
      }
      throw Exception('Error de conexión: $e');
    }
  }
  
  // Obtener perfil de paciente por accountId
  Future<PatientProfile> getPatientProfileByAccount(int accountId, String token) async {
    try {
      print('Obteniendo perfil de paciente con URL: $baseUrl/patient-profiles/account/$accountId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/patient-profiles/account/$accountId'),
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
        return PatientProfile.fromJson(_parseResponse(response));
      } else if (response.statusCode == 401) {
        throw Exception('Token inválido o expirado');
      } else {
        final errorBody = _parseResponse(response);
        throw Exception('Error al obtener perfil: ${errorBody['message'] ?? response.body}');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Failed host lookup')) {
        throw Exception('No se puede conectar al servidor. Verifica la URL y que el backend esté ejecutándose.');
      }
      throw Exception('Error de conexión: $e');
    }
  }
}