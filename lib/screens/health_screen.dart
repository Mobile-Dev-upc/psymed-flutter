// lib/screens/health_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/patient_report_provider.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  int selectedMood = -1;
  final List<String> moods = ["😢", "😟", "😐", "😊", "😄"];

  final Map<String, int> ratings = {
    "Hunger": 0,
    "Hydration": 0,
    "Sleep Quality": 0,
    "Energy Level": 0,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReports();
    });
  }

  Future<void> _loadReports() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final reportProvider = Provider.of<PatientReportProvider>(context, listen: false);

    if (authProvider.patientProfile != null && authProvider.token != null) {
      await reportProvider.loadTodayReports(
        authProvider.patientProfile!.id,
        authProvider.token!,
      );
    }
  }

  bool _hasReportedToday() {
    final reportProvider = Provider.of<PatientReportProvider>(context, listen: false);
    return reportProvider.hasReportedToday();
  }

  String _getLastReportDate() {
    final reportProvider = Provider.of<PatientReportProvider>(context, listen: false);
    if (reportProvider.moodStates.isEmpty) return '';
    
    // Assuming the backend returns the most recent first or we take the last one
    final lastMood = reportProvider.moodStates.last;
    // You might need to add a timestamp field to your MoodState model
    return DateFormat('dd/MM/yyyy').format(DateTime.now());
  }

  Future<void> _saveReport() async {
    // Verificar si ya se registró hoy
    if (_hasReportedToday()) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange),
              SizedBox(width: 10),
              Text('Ya registrado'),
            ],
          ),
          content: const Text(
            'Ya has registrado tu estado de ánimo hoy. Solo puedes registrarlo una vez al día.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
      return;
    }

    if (selectedMood == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona tu estado de ánimo'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (ratings.values.any((rating) => rating == 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa todas las calificaciones'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final reportProvider = Provider.of<PatientReportProvider>(context, listen: false);

    if (authProvider.patientProfile == null || authProvider.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No se pudo obtener información del usuario'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success = await reportProvider.saveReport(
      patientId: authProvider.patientProfile!.id,
      token: authProvider.token!,
      moodStatus: selectedMood,
      hunger: ratings["Hunger"]!,
      hydration: ratings["Hydration"]!,
      sleep: ratings["Sleep Quality"]!,
      energy: ratings["Energy Level"]!,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Reporte guardado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      // Resetear formulario
      setState(() {
        selectedMood = -1;
        ratings.updateAll((key, value) => 0);
      });
      // Recargar para actualizar el estado
      await _loadReports();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(reportProvider.errorMessage ?? 'Error al guardar reporte'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Health"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReports,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Consumer<PatientReportProvider>(
        builder: (context, reportProvider, child) {
          final hasReportedToday = reportProvider.hasReportedToday();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner informativo si ya registró hoy
                if (hasReportedToday)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '¡Registro completado!',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Ya registraste tu estado de ánimo hoy. Vuelve mañana.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                const Text(
                  "Log Your Mood",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                const Text("Mood", style: TextStyle(fontSize: 16)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(moods.length, (index) {
                    return GestureDetector(
                      onTap: (reportProvider.isSaving || hasReportedToday)
                          ? null
                          : () {
                              setState(() => selectedMood = index);
                            },
                      child: Opacity(
                        opacity: hasReportedToday ? 0.5 : 1.0,
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: selectedMood == index
                              ? Colors.blue[100]
                              : Colors.grey[200],
                          child: Text(
                            moods[index],
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                ...ratings.keys
                    .map((category) => _buildRatingRow(
                          category,
                          reportProvider.isSaving || hasReportedToday,
                        ))
                    .toList(),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasReportedToday 
                          ? Colors.grey 
                          : Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: (reportProvider.isSaving || hasReportedToday) 
                        ? null 
                        : _saveReport,
                    child: reportProvider.isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            hasReportedToday 
                                ? "Ya registrado hoy" 
                                : "Save",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRatingRow(String category, bool isDisabled) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(category, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              int value = index + 1;
              return GestureDetector(
                onTap: isDisabled
                    ? null
                    : () {
                        setState(() => ratings[category] = value);
                      },
                child: Opacity(
                  opacity: isDisabled ? 0.5 : 1.0,
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      color: ratings[category] == value
                          ? Colors.blue[100]
                          : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(value.toString()),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}