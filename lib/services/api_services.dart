// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class ApiService {
  // IMPORTANTE: Cambia esta URL según tu entorno
  // Para emulador Android usa: http://10.0.2.2:8080/api/v1
  // Para emulador iOS usa: http://localhost:8080/api/v1
  // Para dispositivo físico usa tu IP local: http://192.168.x.x:8080/api/v1
  static const String baseUrl = 'https://psymed-backend-new.onrender.com/api/v1';
  
  // Helper method para manejar respuestas y errores
  dynamic _parseResponse(http.Response response) {
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
  Future<PatientProfile> createPatientProfile(PatientProfileRequest request, String token) async {
    try {
      print('Creando perfil de paciente con URL: $baseUrl/patient-profiles');
      print('Datos: ${json.encode(request.toJson())}');
      print('Token: ${token.substring(0, 20)}...');
      
      final response = await http.post(
        Uri.parse('$baseUrl/patient-profiles'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(request.toJson()),
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return PatientProfile.fromJson(_parseResponse(response));
      } else if (response.statusCode == 401) {
        throw Exception('Token inválido o expirado');
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
  
  // Crear perfil de profesional
  Future<ProfessionalProfile> createProfessionalProfile(ProfessionalProfileRequest request) async {
    try {
      print('Creando perfil de profesional con URL: $baseUrl/professional-profiles');
      print('Datos: ${json.encode(request.toJson())}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/professional-profiles'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(request.toJson()),
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return ProfessionalProfile.fromJson(_parseResponse(response));
      } else {
        if (response.body.isNotEmpty) {
          final errorBody = _parseResponse(response);
          throw Exception('Error al crear perfil: ${errorBody['message'] ?? response.body}');
        } else {
          throw Exception('Error al crear perfil. Status: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Exception en createProfessionalProfile: $e');
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Failed host lookup')) {
        throw Exception('No se puede conectar al servidor. Verifica la URL y que el backend esté ejecutándose.');
      }
      throw Exception('Error de conexión: $e');
    }
  }
  
  // Obtener perfil de profesional por accountId
  Future<ProfessionalProfile> getProfessionalProfileByAccount(int accountId, String token) async {
    try {
      print('Obteniendo perfil de profesional con URL: $baseUrl/professional-profiles/account/$accountId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/professional-profiles/account/$accountId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        return ProfessionalProfile.fromJson(_parseResponse(response));
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
  
  // Obtener pacientes de un profesional
  Future<List<PatientSummary>> getPatientsByProfessional(int professionalId, String token) async {
    try {
      print('========================================');
      print('Obteniendo pacientes del profesional');
      print('Professional ID: $professionalId');
      print('URL: $baseUrl/patient-profiles/professional/$professionalId');
      print('Token: ${token.substring(0, 20)}...');
      print('========================================');
      
      final response = await http.get(
        Uri.parse('$baseUrl/patient-profiles/professional/$professionalId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final dynamic parsedResponse = _parseResponse(response);
        print('Parsed Response Type: ${parsedResponse.runtimeType}');
        print('Parsed Response: $parsedResponse');
        
        // Verificar si la respuesta es una lista o un objeto que contiene una lista
        List<dynamic> jsonList;
        if (parsedResponse is List) {
          jsonList = parsedResponse;
        } else if (parsedResponse is Map && parsedResponse.containsKey('content')) {
          // Si el backend devuelve un objeto paginado
          jsonList = parsedResponse['content'] as List;
        } else if (parsedResponse is Map && parsedResponse.containsKey('data')) {
          jsonList = parsedResponse['data'] as List;
        } else {
          print('Formato de respuesta no esperado: $parsedResponse');
          return [];
        }
        
        print('Número de pacientes encontrados: ${jsonList.length}');
        
        final patients = jsonList.map((json) {
          try {
            return PatientSummary.fromJson(json);
          } catch (e) {
            print('Error parseando paciente: $json');
            print('Error: $e');
            rethrow;
          }
        }).toList();
        
        print('Pacientes parseados correctamente: ${patients.length}');
        return patients;
      } else if (response.statusCode == 404) {
        print('No se encontraron pacientes (404)');
        return [];
      } else if (response.statusCode == 401) {
        throw Exception('Token inválido o expirado');
      } else {
        try {
          final errorBody = _parseResponse(response);
          throw Exception('Error al obtener pacientes: ${errorBody['message'] ?? response.body}');
        } catch (e) {
          throw Exception('Error al obtener pacientes. Status: ${response.statusCode}, Body: ${response.body}');
        }
      }
    } catch (e) {
      print('EXCEPTION en getPatientsByProfessional: $e');
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Failed host lookup')) {
        throw Exception('No se puede conectar al servidor. Verifica la URL y que el backend esté ejecutándose.');
      }
      rethrow;
    }
  }
  
  // Obtener perfil completo de un paciente por su ID
  Future<PatientProfile> getPatientProfileById(int patientId, String token) async {
    try {
      print('Obteniendo perfil de paciente con URL: $baseUrl/patient-profiles/$patientId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/patient-profiles/$patientId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
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

  // Actualizar perfil de paciente
  Future<PatientProfile> updatePatientProfile(int patientId, UpdatePatientProfileRequest request, String token) async {
    try {
      print('Actualizando perfil de paciente ID: $patientId');
      
      final response = await http.put(
        Uri.parse('$baseUrl/patient-profiles/$patientId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(request.toJson()),
      );
      
      print('Update Response Status Code: ${response.statusCode}');
      print('Update Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        return PatientProfile.fromJson(_parseResponse(response));
      } else if (response.statusCode == 401) {
        throw Exception('Token inválido o expirado');
      } else {
        final errorBody = _parseResponse(response);
        throw Exception('Error al actualizar perfil: ${errorBody['message'] ?? response.body}');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Failed host lookup')) {
        throw Exception('No se puede conectar al servidor. Verifica la URL y que el backend esté ejecutándose.');
      }
      throw Exception('Error de conexión: $e');
    }
  }

  // Eliminar perfil de paciente
  Future<void> deletePatientProfile(int patientId, String token) async {
    try {
      print('Eliminando perfil de paciente ID: $patientId');
      
      final response = await http.delete(
        Uri.parse('$baseUrl/patient-profiles/$patientId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      print('Delete Response Status Code: ${response.statusCode}');
      
      if (response.statusCode == 204 || response.statusCode == 200) {
        // Eliminación exitosa
        return;
      } else if (response.statusCode == 401) {
        throw Exception('Token inválido o expirado');
      } else if (response.statusCode == 404) {
        throw Exception('Paciente no encontrado');
      } else {
        throw Exception('Error al eliminar perfil. Status: ${response.statusCode}');
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