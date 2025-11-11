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
  ) async {
    try {
      // Calculate analytics from already loaded mood states
      _moodAnalytic = _analyticsService.calculateMoodAnalytics(
        _moodStates,
        patientId,
        year,
        month,
      );
    } catch (e) {
      print('Error calculating mood analytics: $e');
      _error = e.toString();
      _moodAnalytic = null;
    }
  }

  Future<void> loadBiologicalAnalytics(
    int patientId,
    String year,
    String month,
  ) async {
    try {
      // Calculate analytics from already loaded biological functions
      _biologicalAnalytic = _analyticsService.calculateBiologicalAnalytics(
        _biologicalFunctions,
        patientId,
        year,
        month,
      );
    } catch (e) {
      print('Error calculating biological analytics: $e');
      _error = e.toString();
      _biologicalAnalytic = null;
    }
  }

  Future<void> loadMoodStates(int patientId, String token) async {
    try {
      _moodStates = await _analyticsService.getMoodStates(patientId, token);
    } catch (e) {
      print('Error loading mood states: $e');
      _error = e.toString();
      _moodStates = [];
    }
  }

  Future<void> loadBiologicalFunctions(int patientId, String token) async {
    try {
      _biologicalFunctions = await _analyticsService.getBiologicalFunctions(
        patientId,
        token,
      );
    } catch (e) {
      print('Error loading biological functions: $e');
      _error = e.toString();
      _biologicalFunctions = [];
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

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

