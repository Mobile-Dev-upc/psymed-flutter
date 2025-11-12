// lib/screens/patient_detail_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../core/theme/app_colors.dart';
import '../models/user_model.dart';
import '../models/medication_model.dart';
import '../models/session_model.dart';
import '../models/task_model.dart';
import '../models/mood_state_model.dart';
import '../models/biological_functions_model.dart';
import '../services/api_services.dart';
import '../services/medication_service.dart';
import '../services/session_service.dart';
import '../services/task_service.dart';
import '../services/analytics_service.dart';

class PatientDetailScreen extends StatefulWidget {
  final int patientId;
  final String patientName;

  const PatientDetailScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  final MedicationService _medicationService = MedicationService();
  final SessionService _sessionService = SessionService();
  final TaskService _taskService = TaskService();
  final AnalyticsService _analyticsService = AnalyticsService();

  PatientProfile? _patientProfile;
  List<Medication> _medications = [];
  List<Session> _sessions = [];
  List<Task> _tasks = [];
  List<MoodState> _moodStates = [];
  List<BiologicalFunctions> _biologicalFunctions = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadPatientData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPatientData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) {
      setState(() {
        _errorMessage = 'No authentication token';
        _isLoading = false;
      });
      return;
    }

    try {
      final patientProfile =
          await _apiService.getPatientProfileById(widget.patientId, token);
      final medications =
          await _medicationService.getMedicationsByPatient(widget.patientId, token);
      final sessions =
          await _sessionService.getPatientSessions(widget.patientId, token);

      List<Task> tasks = [];
      String? tasksError;
      try {
        tasks = await _taskService.getTasksByPatientId(widget.patientId, token);
      } catch (taskError) {
        tasksError = taskError.toString().replaceAll('Exception: ', '');
        debugPrint('Error loading tasks: $tasksError');
      }

      final moodStates =
          await _analyticsService.getMoodStates(widget.patientId, token);
      final biologicalFunctions =
          await _analyticsService.getBiologicalFunctions(widget.patientId, token);

      setState(() {
        _patientProfile = patientProfile;
        _medications = medications;
        _sessions = sessions;
        _tasks = tasks;
        _moodStates = moodStates;
        _biologicalFunctions = biologicalFunctions;
        _isLoading = false;
      });

      if (tasksError != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Tasks could not be loaded: $tasksError',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.patientName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        backgroundColor: AppColors.cardBackground,
        foregroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined, size: 24),
            onPressed: _loadPatientData,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _errorMessage != null
              ? _buildErrorView()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildInfoTab(),
                    _buildMedicationsTab(),
                    _buildSessionsTab(),
                    _buildTasksTab(),
                  ],
                ),
      bottomNavigationBar: Container(
        color: AppColors.cardBackground,
        child: SafeArea(
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textLight,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            tabs: const [
              Tab(
                text: 'Info',
                icon: Icon(Icons.info_outline, size: 22),
              ),
              Tab(
                text: 'Medications',
                icon: Icon(Icons.medication, size: 22),
              ),
              Tab(
                text: 'Sessions',
                icon: Icon(Icons.calendar_today, size: 22),
              ),
              Tab(
                text: 'Tasks',
                icon: Icon(Icons.task_alt, size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
              color: AppColors.error,
            ),
            const SizedBox(height: 20),
            const Text(
              'Error loading patient data',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadPatientData,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTab() {
    if (_patientProfile == null) {
      return const Center(child: Text('No patient information available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            title: 'Personal Information',
            icon: Icons.person,
            children: [
              _buildInfoRow('Full Name', _patientProfile!.fullName),
              _buildInfoRow('Email', _patientProfile!.email),
              _buildInfoRow('Address', _patientProfile!.streetAddress),
              _buildInfoRow('Patient ID', _patientProfile!.id.toString()),
            ],
          ),
          const SizedBox(height: 16),
          _buildMoodStatisticsCard(),
          const SizedBox(height: 16),
          _buildBiologicalStatisticsCard(),
          const SizedBox(height: 16),
          _buildStatsCard(),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 24),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics, color: AppColors.primary, size: 24),
                SizedBox(width: 10),
                Text(
                  'Statistics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Medications',
                    _medications.length.toString(),
                    Icons.medication,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Sessions',
                    _sessions.length.toString(),
                    Icons.calendar_today,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Tasks',
                    _tasks.length.toString(),
                    Icons.task_alt,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMedicationsTab() {
    return Stack(
      children: [
        if (_medications.isEmpty)
          _buildEmptyState(
            icon: Icons.medication,
            message: 'No medications prescribed',
          )
        else
          ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: _medications.length,
            itemBuilder: (context, index) {
              final medication = _medications[index];
              return _buildMedicationCard(medication);
            },
          ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: _showAddMedicationDialog,
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildMedicationCard(Medication medication) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.medication,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medication.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        medication.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: AppColors.primary, size: 20),
                      onPressed: () => _showEditMedicationDialog(medication),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                      onPressed: () => _confirmDeleteMedication(medication),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildMedicationInfo(
                    'Interval',
                    medication.interval,
                    Icons.schedule,
                  ),
                ),
                Expanded(
                  child: _buildMedicationInfo(
                    'Quantity',
                    medication.quantity,
                    Icons.numbers,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationInfo(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSessionsTab() {
    final sortedSessions = List<Session>.from(_sessions)
      ..sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));

    return Stack(
      children: [
        if (_sessions.isEmpty)
          _buildEmptyState(
            icon: Icons.calendar_today,
            message: 'No sessions scheduled',
          )
        else
          ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            itemCount: sortedSessions.length,
            itemBuilder: (context, index) {
              final session = sortedSessions[index];
              return _buildSessionCard(session);
            },
          ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            heroTag: 'sessionFab',
            onPressed: _showAddSessionDialog,
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildSessionCard(Session session) {
    final dateFormatter = DateFormat('MMM dd, yyyy');
    final timeFormatter = DateFormat('HH:mm');
    final isPast = session.appointmentDate.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isPast
                        ? AppColors.textLight.withOpacity(0.2)
                        : AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    color: isPast ? AppColors.textLight : AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateFormatter.format(session.appointmentDate),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isPast ? AppColors.textLight : AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: isPast
                                ? AppColors.textLight
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timeFormatter.format(session.appointmentDate),
                            style: TextStyle(
                              fontSize: 14,
                              color: isPast
                                  ? AppColors.textLight
                                  : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.timer,
                            size: 14,
                            color: isPast
                                ? AppColors.textLight
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${session.sessionTime}h',
                            style: TextStyle(
                              fontSize: 14,
                              color: isPast
                                  ? AppColors.textLight
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!isPast)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Upcoming',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 20, color: AppColors.primary),
                  tooltip: 'Edit',
                  onPressed: isPast ? null : () => _showEditSessionDialog(session),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                  tooltip: 'Delete',
                  onPressed: () => _confirmDeleteSession(session),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksTab() {
    final completedTasks = _tasks.where((task) => task.status == 1).length;
    final pendingTasks = _tasks.length - completedTasks;

    return Stack(
      children: [
        if (_tasks.isEmpty)
          _buildEmptyState(
            icon: Icons.task_alt,
            message: 'No tasks assigned',
          )
        else
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            children: [
              _buildPatientTaskProgress(
                total: _tasks.length,
                completed: completedTasks,
                pending: pendingTasks,
              ),
              const SizedBox(height: 24),
              ..._tasks.map(_buildTaskCard).toList(),
            ],
          ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            heroTag: 'taskFab',
            onPressed: _showAddTaskDialog,
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.add_task, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildPatientTaskProgress({
    required int total,
    required int completed,
    required int pending,
  }) {
    final completionRate = total == 0 ? 0.0 : (completed / total) * 100;

    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Task Progress',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildProgressStatItem(
                label: 'Completed',
                value: completed.toString(),
                icon: Icons.check_circle,
              ),
              Container(width: 1, height: 40, color: Colors.white30),
              _buildProgressStatItem(
                label: 'Pending',
                value: pending.toString(),
                icon: Icons.pending,
              ),
              Container(width: 1, height: 40, color: Colors.white30),
              _buildProgressStatItem(
                label: 'Rate',
                value: '${completionRate.toStringAsFixed(0)}%',
                icon: Icons.trending_up,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: completionRate / 100,
              backgroundColor: Colors.white30,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStatItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Session _placeholderSession(int sessionId) {
    return Session(
      id: sessionId,
      patientId: widget.patientId,
      professionalId: _patientProfile?.professionalId ?? 0,
      appointmentDate: DateTime.now(),
      sessionTime: 1.0,
    );
  }

  Widget _buildTaskCard(Task task) {
    final isCompleted = task.status == 1;
    final session = _sessions.firstWhere(
      (session) => session.id == task.idSession,
      orElse: () => _placeholderSession(task.idSession),
    );
    final dateFormatter = DateFormat('MMM dd, yyyy');
    final timeFormatter = DateFormat('HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isCompleted ? Icons.check_circle : Icons.pending,
                    color: isCompleted ? Colors.green : Colors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          decoration:
                              isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          decoration:
                              isCompleted ? TextDecoration.lineThrough : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? Colors.green.withOpacity(0.12)
                            : Colors.orange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isCompleted ? 'Completed' : 'Pending',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isCompleted ? Colors.green : Colors.orange,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20, color: AppColors.primary),
                          tooltip: 'Edit',
                          onPressed: () => _showEditTaskDialog(task),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                          tooltip: 'Delete',
                          onPressed: () => _confirmDeleteTask(task),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  '${dateFormatter.format(session.appointmentDate)} • ${timeFormatter.format(session.appointmentDate)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTaskDialog() {
    if (_sessions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No sessions available. Create a session before adding tasks.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    _showTaskDialog();
  }

  void _showEditTaskDialog(Task task) {
    _showTaskDialog(existingTask: task);
  }

  void _showTaskDialog({Task? existingTask}) {
    final isEditing = existingTask != null;
    final formKey = GlobalKey<FormState>();

    Session? selectedSession = isEditing
        ? _sessions.firstWhere(
            (session) => session.id == existingTask!.idSession,
            orElse: () => _sessions.isNotEmpty
                ? _sessions.first
                : _placeholderSession(existingTask.idSession),
          )
        : (_sessions.isNotEmpty ? _sessions.first : null);

    final titleController = TextEditingController(text: existingTask?.title ?? '');
    final descriptionController = TextEditingController(text: existingTask?.description ?? '');
    final dateFormatter = DateFormat('MMM dd, yyyy');
    final timeFormatter = DateFormat('HH:mm');

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(
                    isEditing ? Icons.edit_note : Icons.task_alt,
                    color: AppColors.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isEditing ? 'Edit Task' : 'Add Task',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<Session>(
                        value: selectedSession,
                        items: _sessions
                            .map(
                              (session) => DropdownMenuItem<Session>(
                                value: session,
                                child: Text(
                                  '${dateFormatter.format(session.appointmentDate)} • ${timeFormatter.format(session.appointmentDate)}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: isEditing
                            ? null
                            : (value) {
                                setStateDialog(() {
                                  selectedSession = value;
                                });
                              },
                        decoration: const InputDecoration(
                          labelText: 'Session *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a description';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    FocusScope.of(dialogContext).unfocus();

                    if (!formKey.currentState!.validate()) {
                      return;
                    }

                    if (!isEditing && selectedSession == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select a session for the task'),
                          backgroundColor: Colors.orange,
                          duration: Duration(seconds: 3),
                        ),
                      );
                      return;
                    }

                    Navigator.pop(dialogContext);

                    if (isEditing) {
                      await _updateTask(
                        task: existingTask!,
                        title: titleController.text,
                        description: descriptionController.text,
                      );
                    } else {
                      await _createTask(
                        sessionId: selectedSession!.id,
                        title: titleController.text,
                        description: descriptionController.text,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(isEditing ? 'Update' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteTask(Task task) {
    final dateFormatter = DateFormat('MMM dd, yyyy');
    final timeFormatter = DateFormat('HH:mm');
    final session = _sessions.firstWhere(
      (session) => session.id == task.idSession,
      orElse: () => Session(
        id: task.idSession,
        patientId: widget.patientId,
        professionalId: _patientProfile?.professionalId ?? 0,
        appointmentDate: DateTime.now(),
        sessionTime: 1.0,
      ),
    );
    final taskCreatedAt = task.createdAt ?? session.appointmentDate;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Text(
                'Delete Task',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you sure you want to delete this task?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      task.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${dateFormatter.format(session.appointmentDate)} • ${timeFormatter.format(session.appointmentDate)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Created on ${dateFormatter.format(taskCreatedAt)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '⚠️ This action cannot be undone.',
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _deleteTask(task);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createTask({
    required int sessionId,
    required String title,
    required String description,
  }) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);

    final token = authProvider.token;
    if (token == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Authentication token not found. Please log in again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _taskService.createTask(sessionId, title, description, token);

      if (!mounted) return;

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Task created successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      await _loadPatientData();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error creating task: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateTask({
    required Task task,
    required String title,
    required String description,
  }) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);

    final token = authProvider.token;
    if (token == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Authentication token not found. Please log in again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _taskService.updateTask(
        task.idSession,
        int.parse(task.id),
        title,
        description,
        token,
      );

      if (!mounted) return;

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Task updated successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      await _loadPatientData();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error updating task: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteTask(Task task) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);

    final token = authProvider.token;
    if (token == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Authentication token not found. Please log in again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _taskService.deleteTask(task.idSession, int.parse(task.id), token);

      if (!mounted) return;

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Task deleted successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      await _loadPatientData();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error deleting task: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodStatisticsCard() {
    // Get last 7 days of mood data
    final now = DateTime.now();
    final last7Days = _moodStates.where((mood) {
      if (mood.date == null) return false;
      return now.difference(mood.date!).inDays <= 7;
    }).toList();

    // Sort by date
    last7Days.sort((a, b) => b.date!.compareTo(a.date!));

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.mood, color: AppColors.primary, size: 24),
                const SizedBox(width: 10),
                const Text(
                  'Emotional State',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Last 7 days',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (last7Days.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'No emotional state records yet',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              )
            else
              Column(
                children: [
                  // Mood distribution
                  _buildMoodDistribution(last7Days),
                  const SizedBox(height: 16),
                  // Recent moods list
                  ...last7Days.take(5).map((mood) => _buildMoodItem(mood)),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodDistribution(List<MoodState> moods) {
    // Count each mood type
    final moodCounts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (var mood in moods) {
      moodCounts[mood.mood] = (moodCounts[mood.mood] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMoodCount('😢', moodCounts[1]!, Colors.blue),
          _buildMoodCount('😕', moodCounts[2]!, Colors.blueGrey),
          _buildMoodCount('😐', moodCounts[3]!, Colors.grey),
          _buildMoodCount('😊', moodCounts[4]!, Colors.orange),
          _buildMoodCount('😄', moodCounts[5]!, Colors.green),
        ],
      ),
    );
  }

  Widget _buildMoodCount(String emoji, int count, Color color) {
    return Column(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMoodItem(MoodState mood) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            mood.getMoodEmoji(),
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mood.getMoodLabel(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                if (mood.date != null)
                  Text(
                    DateFormat('MMM dd, yyyy').format(mood.date!),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBiologicalStatisticsCard() {
    // Get current month data
    final now = DateTime.now();
    final currentMonthData = _biologicalFunctions.where((bio) {
      if (bio.date == null) return false;
      return bio.date!.year == now.year && bio.date!.month == now.month;
    }).toList();

    // Calculate averages
    double hungerAvg = 0, hydrationAvg = 0, sleepAvg = 0, energyAvg = 0;
    if (currentMonthData.isNotEmpty) {
      hungerAvg = currentMonthData.map((e) => e.hunger).reduce((a, b) => a + b) / currentMonthData.length;
      hydrationAvg = currentMonthData.map((e) => e.hydration).reduce((a, b) => a + b) / currentMonthData.length;
      sleepAvg = currentMonthData.map((e) => e.sleep).reduce((a, b) => a + b) / currentMonthData.length;
      energyAvg = currentMonthData.map((e) => e.energy).reduce((a, b) => a + b) / currentMonthData.length;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.favorite, color: AppColors.error, size: 24),
                const SizedBox(width: 10),
                const Text(
                  'Physical State',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    DateFormat('MMM yyyy').format(now),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (currentMonthData.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'No physical state records yet',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              )
            else
              Column(
                children: [
                  _buildBiologicalIndicator(
                    '🍽️',
                    'Hunger',
                    hungerAvg,
                    Colors.orange,
                  ),
                  const SizedBox(height: 12),
                  _buildBiologicalIndicator(
                    '💧',
                    'Hydration',
                    hydrationAvg,
                    Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  _buildBiologicalIndicator(
                    '😴',
                    'Sleep',
                    sleepAvg,
                    Colors.indigo,
                  ),
                  const SizedBox(height: 12),
                  _buildBiologicalIndicator(
                    '⚡',
                    'Energy',
                    energyAvg,
                    Colors.yellow,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Based on ${currentMonthData.length} record${currentMonthData.length != 1 ? 's' : ''} this month',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBiologicalIndicator(
    String emoji,
    String label,
    double value,
    Color color,
  ) {
    final percentage = (value / 5.0).clamp(0.0, 1.0);

    return Row(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    '${value.toStringAsFixed(1)}/5.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: color.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAddSessionDialog() {
    _showSessionDialog();
  }

  void _showEditSessionDialog(Session session) {
    _showSessionDialog(existingSession: session);
  }

  void _showSessionDialog({Session? existingSession}) {
    final bool isEditing = existingSession != null;
    final formKey = GlobalKey<FormState>();

    DateTime selectedDateTime =
        existingSession?.appointmentDate ?? DateTime.now().add(const Duration(hours: 1));

    final dateFormatter = DateFormat('yyyy-MM-dd');
    final timeFormatter = DateFormat('HH:mm');

    final dateController = TextEditingController(text: dateFormatter.format(selectedDateTime));
    final timeController = TextEditingController(text: timeFormatter.format(selectedDateTime));

    final initialDuration = existingSession?.sessionTime ?? 1.0;
    final durationController = TextEditingController(
      text: initialDuration % 1 == 0
          ? initialDuration.toInt().toString()
          : initialDuration.toString(),
    );

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Future<void> pickDate() async {
              final pickedDate = await showDatePicker(
                context: dialogContext,
                initialDate: selectedDateTime.isAfter(DateTime.now())
                    ? selectedDateTime
                    : DateTime.now().add(const Duration(days: 1)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );

              if (pickedDate != null) {
                setStateDialog(() {
                  selectedDateTime = DateTime(
                    pickedDate.year,
                    pickedDate.month,
                    pickedDate.day,
                    selectedDateTime.hour,
                    selectedDateTime.minute,
                  );
                  dateController.text = dateFormatter.format(selectedDateTime);
                });
              }
            }

            Future<void> pickTime() async {
              final pickedTime = await showTimePicker(
                context: dialogContext,
                initialTime: TimeOfDay.fromDateTime(selectedDateTime),
              );

              if (pickedTime != null) {
                setStateDialog(() {
                  selectedDateTime = DateTime(
                    selectedDateTime.year,
                    selectedDateTime.month,
                    selectedDateTime.day,
                    pickedTime.hour,
                    pickedTime.minute,
                  );
                  final hour = pickedTime.hour.toString().padLeft(2, '0');
                  final minute = pickedTime.minute.toString().padLeft(2, '0');
                  timeController.text = '$hour:$minute';
                });
              }
            }

            return AlertDialog(
              title: Row(
                children: [
                  Icon(
                    isEditing ? Icons.edit_calendar : Icons.add_circle,
                    color: AppColors.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isEditing ? 'Edit Session' : 'Schedule Session',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: dateController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Date (YYYY-MM-DD) *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        onTap: pickDate,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a date';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: timeController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Time (HH:mm) *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.access_time),
                        ),
                        onTap: pickTime,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a time';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: durationController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Duration in hours *',
                          hintText: 'Example: 1, 1.5, 2',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.timer),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a duration';
                          }
                          final sanitized = value.replaceAll(',', '.');
                          final parsed = double.tryParse(sanitized);
                          if (parsed == null || parsed <= 0) {
                            return 'Duration must be greater than 0';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    FocusScope.of(dialogContext).unfocus();
                    if (!formKey.currentState!.validate()) return;

                    if (!selectedDateTime.isAfter(DateTime.now())) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('The session date must be in the future'),
                          backgroundColor: Colors.orange,
                          duration: Duration(seconds: 3),
                        ),
                      );
                      return;
                    }

                    final durationValue =
                        double.parse(durationController.text.replaceAll(',', '.'));

                    Navigator.pop(dialogContext);

                    if (isEditing) {
                      await _updateSession(
                        sessionId: existingSession!.id,
                        appointmentDate: selectedDateTime,
                        sessionTime: durationValue,
                      );
                    } else {
                      await _createSession(
                        appointmentDate: selectedDateTime,
                        sessionTime: durationValue,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(isEditing ? 'Update' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteSession(Session session) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final dateFormatter = DateFormat('MMM dd, yyyy');
        final timeFormatter = DateFormat('HH:mm');

        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Text(
                'Delete Session',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you sure you want to delete this session?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateFormatter.format(session.appointmentDate),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${timeFormatter.format(session.appointmentDate)} - ${session.sessionTime}h',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '⚠️ This action cannot be undone.',
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _deleteSession(session.id);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createSession({
    required DateTime appointmentDate,
    required double sessionTime,
  }) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);

    final professionalId = authProvider.professionalProfile?.id;
    final token = authProvider.token;

    if (professionalId == null || token == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Unable to identify the professional. Please log in again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final request = SessionCreateRequest(
        appointmentDate: appointmentDate,
        sessionTime: sessionTime,
      );

      await _sessionService.createSession(
        professionalId: professionalId,
        patientId: widget.patientId,
        request: request,
        token: token,
      );

      if (!mounted) return;

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Session scheduled successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      await _loadPatientData();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error scheduling session: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateSession({
    required int sessionId,
    required DateTime appointmentDate,
    required double sessionTime,
  }) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);

    final professionalId = authProvider.professionalProfile?.id;
    final token = authProvider.token;

    if (professionalId == null || token == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Unable to identify the professional. Please log in again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final request = SessionUpdateRequest(
        appointmentDate: appointmentDate,
        sessionTime: sessionTime,
      );

      await _sessionService.updateSession(
        professionalId: professionalId,
        patientId: widget.patientId,
        sessionId: sessionId,
        request: request,
        token: token,
      );

      if (!mounted) return;

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Session updated successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      await _loadPatientData();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error updating session: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteSession(int sessionId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);

    final professionalId = authProvider.professionalProfile?.id;
    final token = authProvider.token;

    if (professionalId == null || token == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Unable to identify the professional. Please log in again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _sessionService.deleteSession(
        professionalId: professionalId,
        patientId: widget.patientId,
        sessionId: sessionId,
        token: token,
      );

      if (!mounted) return;

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Session deleted successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      await _loadPatientData();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error deleting session: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Diálogo para agregar medicamento
  void _showAddMedicationDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final intervalController = TextEditingController();
    final quantityController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.add_circle, color: AppColors.primary, size: 28),
              SizedBox(width: 10),
              Text('Add Medication', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Medication Name *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.medication),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter medication name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 2,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: intervalController,
                    decoration: const InputDecoration(
                      labelText: 'Interval (e.g., Every 8 hours) *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.schedule),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter interval';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity (e.g., 1 tablet) *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.numbers),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter quantity';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext);
                  await _addMedication(
                    nameController.text,
                    descriptionController.text,
                    intervalController.text,
                    quantityController.text,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  // Diálogo para editar medicamento
  void _showEditMedicationDialog(Medication medication) {
    final nameController = TextEditingController(text: medication.name);
    final descriptionController = TextEditingController(text: medication.description);
    final intervalController = TextEditingController(text: medication.interval);
    final quantityController = TextEditingController(text: medication.quantity);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.edit, color: AppColors.primary, size: 28),
              SizedBox(width: 10),
              Text('Edit Medication', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Medication Name *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.medication),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter medication name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 2,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: intervalController,
                    decoration: const InputDecoration(
                      labelText: 'Interval (e.g., Every 8 hours) *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.schedule),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter interval';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity (e.g., 1 tablet) *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.numbers),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter quantity';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext);
                  await _updateMedication(
                    medication.id,
                    nameController.text,
                    descriptionController.text,
                    intervalController.text,
                    quantityController.text,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  // Confirmación para eliminar medicamento
  void _confirmDeleteMedication(Medication medication) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Text('Delete Medication', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you sure you want to delete this medication?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medication.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      medication.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '⚠️ This action cannot be undone.',
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _deleteMedication(medication.id);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // Agregar medicamento
  Future<void> _addMedication(String name, String description, String interval, String quantity) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _isLoading = true;
    });

    try {
      final request = MedicationRequest(
        name: name,
        description: description,
        patientId: widget.patientId,
        interval: interval,
        quantity: quantity,
      );

      await _medicationService.createMedication(request, authProvider.token!);

      if (!mounted) return;

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Medication added successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Recargar datos
      await _loadPatientData();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error adding medication: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Actualizar medicamento
  Future<void> _updateMedication(int medicationId, String name, String description, String interval, String quantity) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _isLoading = true;
    });

    try {
      final request = MedicationUpdateRequest(
        name: name,
        description: description,
        interval: interval,
        quantity: quantity,
      );

      await _medicationService.updateMedication(medicationId, request, authProvider.token!);

      if (!mounted) return;

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Medication updated successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Recargar datos
      await _loadPatientData();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error updating medication: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Eliminar medicamento
  Future<void> _deleteMedication(int medicationId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _isLoading = true;
    });

    try {
      await _medicationService.deleteMedication(medicationId, authProvider.token!);

      if (!mounted) return;

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Medication deleted successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Recargar datos
      await _loadPatientData();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error deleting medication: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

