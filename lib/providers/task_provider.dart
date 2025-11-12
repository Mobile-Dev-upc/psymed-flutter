// lib/providers/task_provider.dart
import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';

class TaskProvider with ChangeNotifier {
  final TaskService _taskService = TaskService();
  
  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _error;

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Task> get completedTasks => _tasks.where((task) => task.status == 1).toList();
  List<Task> get pendingTasks => _tasks.where((task) => task.status == 0).toList();
  
  double get completionRate {
    if (_tasks.isEmpty) return 0;
    return (completedTasks.length / _tasks.length) * 100;
  }

  Future<void> loadTasksByPatientId(int patientId, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _tasks = await _taskService.getTasksByPatientId(patientId, token);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _tasks = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTasksBySessionId(int sessionId, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _tasks = await _taskService.getTasksBySessionId(sessionId, token);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _tasks = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleTaskStatus(Task task, String token) async {
    try {
      if (task.status == 0) {
        await _taskService.markTaskComplete(task.idSession, int.parse(task.id), token);
      } else {
        await _taskService.markTaskIncomplete(task.idSession, int.parse(task.id), token);
      }
      
      // Update local state
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = task.copyWith(status: task.status == 0 ? 1 : 0);
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> createTask(
    int sessionId,
    String title,
    String description,
    String token,
  ) async {
    try {
      final newTask = await _taskService.createTask(
        sessionId,
        title,
        description,
        token,
      );
      _tasks.add(newTask);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTask(Task task, String token) async {
    try {
      await _taskService.deleteTask(task.idSession, int.parse(task.id), token);
      _tasks.removeWhere((t) => t.id == task.id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTask(
    Task task,
    String title,
    String description,
    String token,
  ) async {
    try {
      final updatedTask = await _taskService.updateTask(
        task.idSession,
        int.parse(task.id),
        title,
        description,
        token,
      );

      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = updatedTask;
        notifyListeners();
      }

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

