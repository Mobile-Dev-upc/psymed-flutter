// lib/providers/analytics_provider.dart
import 'package:flutter/material.dart';
import '../models/mood_state_model.dart';
import '../models/biological_functions_model.dart';
import '../services/analytics_service.dart';

class AnalyticsProvider with ChangeNotifier {
  final AnalyticsService _analyticsService = AnalyticsService();
  
  MoodAnalytic? _moodAnalytic;
  BiologicalAnalytic? _biologicalAnalytic;
  List<MoodState> _moodStates = [];
  List<BiologicalFunctions> _biologicalFunctions = [];
  
  bool _isLoading = false;
  String? _error;

  MoodAnalytic? get moodAnalytic => _moodAnalytic;
  BiologicalAnalytic? get biologicalAnalytic => _biologicalAnalytic;
  List<MoodState> get moodStates => _moodStates;
  List<BiologicalFunctions> get biologicalFunctions => _biologicalFunctions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadMoodAnalytics(
    int patientId,
    String year,
    String month,
    String token,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _moodAnalytic = await _analyticsService.getMoodAnalytics(
        patientId,
        year,
        month,
        token,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
      _moodAnalytic = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadBiologicalAnalytics(
    int patientId,
    String year,
    String month,
    String token,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _biologicalAnalytic = await _analyticsService.getBiologicalAnalytics(
        patientId,
        year,
        month,
        token,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
      _biologicalAnalytic = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoodStates(int patientId, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _moodStates = await _analyticsService.getMoodStates(patientId, token);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _moodStates = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadBiologicalFunctions(int patientId, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _biologicalFunctions = await _analyticsService.getBiologicalFunctions(
        patientId,
        token,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
      _biologicalFunctions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createMoodState(int patientId, int mood, String token) async {
    try {
      final newMoodState = await _analyticsService.createMoodState(
        patientId,
        mood,
        token,
      );
      _moodStates.add(newMoodState);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> createBiologicalFunction(
    int patientId,
    int hunger,
    int hydration,
    int sleep,
    int energy,
    String token,
  ) async {
    try {
      final newBiologicalFunction = await _analyticsService.createBiologicalFunction(
        patientId,
        hunger,
        hydration,
        sleep,
        energy,
        token,
      );
      _biologicalFunctions.add(newBiologicalFunction);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

