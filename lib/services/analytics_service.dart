// lib/services/analytics_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/mood_state_model.dart';
import '../models/biological_functions_model.dart';
import 'api_services.dart';

class AnalyticsService {
  // Calculate mood analytics from mood states
  MoodAnalytic calculateMoodAnalytics(
    List<MoodState> moodStates,
    int patientId,
    String year,
    String month,
  ) {
    // Filter by month and year if needed
    final filteredMoods = moodStates.where((mood) {
      if (mood.date == null) return false;
      return mood.date!.year.toString() == year &&
          mood.date!.month.toString() == month;
    }).toList();
    
    // Count each mood type (mapping Flutter values 1-5 to backend values 0-4)
    int soSadCount = 0;
    int sadCount = 0;
    int neutralCount = 0;
    int happyCount = 0;
    int soHappyCount = 0;
    
    for (var mood in filteredMoods) {
      switch (mood.mood) {
        case 1: // So Sad
          soSadCount++;
          break;
        case 2: // Sad
          sadCount++;
          break;
        case 3: // Neutral
          neutralCount++;
          break;
        case 4: // Happy
          happyCount++;
          break;
        case 5: // So Happy
          soHappyCount++;
          break;
      }
    }
    
    return MoodAnalytic(
      idPatient: patientId.toString(),
      year: year,
      month: month,
      sadMood: sadCount,
      happyMood: happyCount,
      neutralMood: neutralCount,
      soSadMood: soSadCount,
      soHappyMood: soHappyCount,
    );
  }

  // Calculate biological analytics from biological functions
  BiologicalAnalytic calculateBiologicalAnalytics(
    List<BiologicalFunctions> biologicalFunctions,
    int patientId,
    String year,
    String month,
  ) {
    // Filter by month and year
    final filtered = biologicalFunctions.where((bio) {
      if (bio.date == null) return false;
      return bio.date!.year.toString() == year &&
          bio.date!.month.toString() == month;
    }).toList();
    
    if (filtered.isEmpty) {
      return BiologicalAnalytic(
        idPatient: patientId.toString(),
        month: month,
        year: year,
        hungerAverage: 0,
        sleepAverage: 0,
        energyAverage: 0,
        hydrationAverage: 0,
      );
    }
    
    // Calculate averages
    double hungerSum = 0;
    double hydrationSum = 0;
    double sleepSum = 0;
    double energySum = 0;
    
    for (var bio in filtered) {
      hungerSum += bio.hunger;
      hydrationSum += bio.hydration;
      sleepSum += bio.sleep;
      energySum += bio.energy;
    }
    
    final count = filtered.length;
    
    return BiologicalAnalytic(
      idPatient: patientId.toString(),
      month: month,
      year: year,
      hungerAverage: hungerSum / count,
      sleepAverage: sleepSum / count,
      energyAverage: energySum / count,
      hydrationAverage: hydrationSum / count,
    );
  }

  // Get all mood states for a patient
  Future<List<MoodState>> getMoodStates(int patientId, String token) async {
    try {
      print('Fetching mood states for patient: $patientId');
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/patients/$patientId/mood-states'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));
      
      print('Mood states response: ${response.statusCode}');
      print('Mood states body: ${response.body}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => MoodState.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener estados de ánimo: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception in getMoodStates: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  // Get all biological functions for a patient
  Future<List<BiologicalFunctions>> getBiologicalFunctions(
    int patientId,
    String token,
  ) async {
    try {
      print('Fetching biological functions for patient: $patientId');
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/patients/$patientId/biological-functions'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));
      
      print('Biological functions response: ${response.statusCode}');
      print('Biological functions body: ${response.body}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => BiologicalFunctions.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener funciones biológicas: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception in getBiologicalFunctions: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  // Create mood state (mood values: 1=So Sad, 2=Sad, 3=Neutral, 4=Happy, 5=So Happy)
  // Backend expects: 0=SOSAD, 1=SAD, 2=NORMAL, 3=HAPPY, 4=SOHAPPY
  Future<MoodState> createMoodState(
    int patientId,
    int mood,
    String token,
  ) async {
    try {
      // Convert Flutter mood (1-5) to backend mood (0-4)
      final backendMood = mood - 1;
      
      print('Creating mood state: patient=$patientId, mood=$mood (backend=$backendMood)');
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/patients/$patientId/mood-states'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'status': backendMood,
        }),
      ).timeout(const Duration(seconds: 10));
      
      print('Create mood state response: ${response.statusCode}');
      print('Create mood state body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return MoodState.fromJson(json.decode(response.body));
      } else {
        throw Exception('Error al crear estado de ánimo: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception in createMoodState: $e');
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
      print('Creating biological function: patient=$patientId');
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/patients/$patientId/biological-functions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'hunger': hunger,
          'hydration': hydration,
          'sleep': sleep,
          'energy': energy,
        }),
      ).timeout(const Duration(seconds: 10));
      
      print('Create biological function response: ${response.statusCode}');
      print('Create biological function body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return BiologicalFunctions.fromJson(json.decode(response.body));
      } else {
        throw Exception('Error al crear registro biológico: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception in createBiologicalFunction: $e');
      throw Exception('Error de conexión: $e');
    }
  }
}

