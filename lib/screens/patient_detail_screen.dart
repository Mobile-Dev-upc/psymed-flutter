// lib/screens/patient_detail_screen.dart
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
      // Cargar datos en paralelo
      final results = await Future.wait([
        _apiService.getPatientProfileById(widget.patientId, token),
        _medicationService.getMedicationsByPatient(widget.patientId, token),
        _sessionService.getPatientSessions(widget.patientId, token),
        _taskService.getTasksByPatientId(widget.patientId, token),
        _analyticsService.getMoodStates(widget.patientId, token),
        _analyticsService.getBiologicalFunctions(widget.patientId, token),
      ]);

      setState(() {
        _patientProfile = results[0] as PatientProfile;
        _medications = results[1] as List<Medication>;
        _sessions = results[2] as List<Session>;
        _tasks = results[3] as List<Task>;
        _moodStates = results[4] as List<MoodState>;
        _biologicalFunctions = results[5] as List<BiologicalFunctions>;
        _isLoading = false;
      });
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
    if (_medications.isEmpty) {
      return _buildEmptyState(
        icon: Icons.medication,
        message: 'No medications prescribed',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _medications.length,
      itemBuilder: (context, index) {
        final medication = _medications[index];
        return _buildMedicationCard(medication);
      },
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
    if (_sessions.isEmpty) {
      return _buildEmptyState(
        icon: Icons.calendar_today,
        message: 'No sessions scheduled',
      );
    }

    // Ordenar sesiones por fecha (más recientes primero)
    final sortedSessions = List<Session>.from(_sessions)
      ..sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: sortedSessions.length,
      itemBuilder: (context, index) {
        final session = sortedSessions[index];
        return _buildSessionCard(session);
      },
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
        child: Row(
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
      ),
    );
  }

  Widget _buildTasksTab() {
    if (_tasks.isEmpty) {
      return _buildEmptyState(
        icon: Icons.task_alt,
        message: 'No tasks assigned',
      );
    }

    final completedTasks = _tasks.where((task) => task.status == 1).length;
    final pendingTasks = _tasks.length - completedTasks;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTaskStat('Total', _tasks.length.toString(), Colors.blue),
              _buildTaskStat(
                  'Pending', pendingTasks.toString(), Colors.orange),
              _buildTaskStat(
                  'Completed', completedTasks.toString(), Colors.green),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: _tasks.length,
            itemBuilder: (context, index) {
              final task = _tasks[index];
              return _buildTaskCard(task);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTaskStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
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

  Widget _buildTaskCard(Task task) {
    final isCompleted = task.status == 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
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
          ],
        ),
      ),
    );
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
}

