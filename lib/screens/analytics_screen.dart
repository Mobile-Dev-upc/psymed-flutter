// lib/screens/analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/analytics_provider.dart';
import '../providers/auth_provider.dart';
import '../models/mood_state_model.dart';
import '../models/biological_functions_model.dart';
import '../core/theme/app_colors.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Use addPostFrameCallback to avoid calling setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAnalytics();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final analyticsProvider = Provider.of<AnalyticsProvider>(context, listen: false);
    
    if (authProvider.patientProfile?.id == null || authProvider.token == null) {
      print('Cannot load analytics: Missing patient profile or token');
      return;
    }

    // Set loading state
    analyticsProvider.setLoading(true);
    
    try {
      final now = DateTime.now();
      final year = now.year.toString();
      final month = now.month.toString();
      
      print('Loading analytics for patient ${authProvider.patientProfile!.id}, year: $year, month: $month');
      
      // Step 1: Load raw data first
      await Future.wait([
        analyticsProvider.loadMoodStates(
          authProvider.patientProfile!.id,
          authProvider.token!,
        ),
        analyticsProvider.loadBiologicalFunctions(
          authProvider.patientProfile!.id,
          authProvider.token!,
        ),
      ]);
      
      print('Raw data loaded successfully');
      
      // Step 2: Calculate analytics from the loaded data
      await Future.wait([
        analyticsProvider.loadMoodAnalytics(
          authProvider.patientProfile!.id,
          year,
          month,
        ),
        analyticsProvider.loadBiologicalAnalytics(
          authProvider.patientProfile!.id,
          year,
          month,
        ),
      ]);
      
      print('Analytics calculated successfully');
    } catch (e) {
      print('Error in _loadAnalytics: $e');
    } finally {
      // Clear loading state and notify listeners once
      analyticsProvider.setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AnalyticsProvider>(
      builder: (context, analyticsProvider, child) {
        if (analyticsProvider.isLoading) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: Colors.grey[100],
          body: Column(
            children: [
              // TabBar sin AppBar
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.black,
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(text: 'Emotional State'),
                    Tab(text: 'Physical Health'),
                  ],
                ),
              ),
              // TabBarView
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadAnalytics,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildEmotionalTab(analyticsProvider),
                      _buildPhysicalTab(analyticsProvider),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmotionalTab(AnalyticsProvider analyticsProvider) {
    final moodAnalytic = analyticsProvider.moodAnalytic;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mood Distribution Pie Chart
          if (moodAnalytic != null && moodAnalytic.totalMoods > 0) ...[
            _buildSectionTitle('Mood Distribution'),
            const SizedBox(height: 16),
            _buildMoodPieChart(moodAnalytic),
            const SizedBox(height: 24),
            _buildMoodLegend(moodAnalytic),
            const SizedBox(height: 32),
          ],
          
          // Recent Mood Entries
          _buildSectionTitle('Recent Mood Entries'),
          const SizedBox(height: 16),
          if (analyticsProvider.moodStates.isEmpty)
            _buildEmptyState('No mood entries yet', Icons.mood)
          else
            ...analyticsProvider.moodStates
                .take(10)
                .map((mood) => _buildMoodCard(mood)),
        ],
      ),
    );
  }

  Widget _buildPhysicalTab(AnalyticsProvider analyticsProvider) {
    final biologicalAnalytic = analyticsProvider.biologicalAnalytic;
    final biologicalFunctions = analyticsProvider.biologicalFunctions;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Average Metrics
          if (biologicalAnalytic != null) ...[
            _buildSectionTitle('Monthly Averages'),
            const SizedBox(height: 16),
            _buildBiologicalAveragesCard(biologicalAnalytic),
            const SizedBox(height: 24),
            _buildBiologicalBarChart(biologicalAnalytic),
            const SizedBox(height: 32),
          ],
          
          // Weekly Trend
          if (biologicalFunctions.isNotEmpty) ...[
            _buildSectionTitle('Weekly Trend'),
            const SizedBox(height: 16),
            _buildBiologicalLineChart(biologicalFunctions),
            const SizedBox(height: 32),
          ],
          
          // Recent Entries
          _buildSectionTitle('Recent Entries'),
          const SizedBox(height: 16),
          if (biologicalFunctions.isEmpty)
            _buildEmptyState('No biological entries yet', Icons.favorite)
          else
            ...biologicalFunctions
                .take(10)
                .map((bio) => _buildBiologicalCard(bio)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildMoodPieChart(MoodAnalytic moodAnalytic) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 60,
          sections: [
            if (moodAnalytic.soSadMood > 0)
              PieChartSectionData(
                value: moodAnalytic.soSadMood.toDouble(),
                title: '${((moodAnalytic.soSadMood / moodAnalytic.totalMoods) * 100).toStringAsFixed(0)}%',
                color: const Color(0xFFEF4444),
                radius: 50,
                titleStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            if (moodAnalytic.sadMood > 0)
              PieChartSectionData(
                value: moodAnalytic.sadMood.toDouble(),
                title: '${((moodAnalytic.sadMood / moodAnalytic.totalMoods) * 100).toStringAsFixed(0)}%',
                color: const Color(0xFFF97316),
                radius: 50,
                titleStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            if (moodAnalytic.neutralMood > 0)
              PieChartSectionData(
                value: moodAnalytic.neutralMood.toDouble(),
                title: '${((moodAnalytic.neutralMood / moodAnalytic.totalMoods) * 100).toStringAsFixed(0)}%',
                color: const Color(0xFF6B7280),
                radius: 50,
                titleStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            if (moodAnalytic.happyMood > 0)
              PieChartSectionData(
                value: moodAnalytic.happyMood.toDouble(),
                title: '${((moodAnalytic.happyMood / moodAnalytic.totalMoods) * 100).toStringAsFixed(0)}%',
                color: const Color(0xFF10B981),
                radius: 50,
                titleStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            if (moodAnalytic.soHappyMood > 0)
              PieChartSectionData(
                value: moodAnalytic.soHappyMood.toDouble(),
                title: '${((moodAnalytic.soHappyMood / moodAnalytic.totalMoods) * 100).toStringAsFixed(0)}%',
                color: const Color(0xFF3B82F6),
                radius: 50,
                titleStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodLegend(MoodAnalytic moodAnalytic) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (moodAnalytic.soSadMood > 0)
            _buildLegendItem('So Sad 😢', moodAnalytic.soSadMood, const Color(0xFFEF4444)),
          if (moodAnalytic.sadMood > 0)
            _buildLegendItem('Sad 😕', moodAnalytic.sadMood, const Color(0xFFF97316)),
          if (moodAnalytic.neutralMood > 0)
            _buildLegendItem('Neutral 😐', moodAnalytic.neutralMood, const Color(0xFF6B7280)),
          if (moodAnalytic.happyMood > 0)
            _buildLegendItem('Happy 😊', moodAnalytic.happyMood, const Color(0xFF10B981)),
          if (moodAnalytic.soHappyMood > 0)
            _buildLegendItem('So Happy 😄', moodAnalytic.soHappyMood, const Color(0xFF3B82F6)),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBiologicalAveragesCard(BiologicalAnalytic analytic) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  '🍽️',
                  'Hunger',
                  analytic.hungerAverage.toStringAsFixed(1),
                  Colors.orange,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  '💧',
                  'Hydration',
                  analytic.hydrationAverage.toStringAsFixed(1),
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  '😴',
                  'Sleep',
                  analytic.sleepAverage.toStringAsFixed(1),
                  Colors.purple,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  '⚡',
                  'Energy',
                  analytic.energyAverage.toStringAsFixed(1),
                  Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String emoji, String label, String value, Color color) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 32)),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildBiologicalBarChart(BiologicalAnalytic analytic) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 10,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const titles = ['Hunger', 'Hydration', 'Sleep', 'Energy'];
                  if (value.toInt() < titles.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        titles[value.toInt()],
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 12),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 2,
          ),
          borderData: FlBorderData(show: false),
          barGroups: [
            BarChartGroupData(
              x: 0,
              barRods: [
                BarChartRodData(
                  toY: analytic.hungerAverage,
                  color: Colors.orange,
                  width: 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            ),
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(
                  toY: analytic.hydrationAverage,
                  color: Colors.blue,
                  width: 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            ),
            BarChartGroupData(
              x: 2,
              barRods: [
                BarChartRodData(
                  toY: analytic.sleepAverage,
                  color: Colors.purple,
                  width: 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            ),
            BarChartGroupData(
              x: 3,
              barRods: [
                BarChartRodData(
                  toY: analytic.energyAverage,
                  color: Colors.green,
                  width: 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBiologicalLineChart(List<BiologicalFunctions> biologicalFunctions) {
    // Get last 7 days
    final last7Days = biologicalFunctions.take(7).toList().reversed.toList();
    
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(
            show: true,
            drawVerticalLine: false,
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < last7Days.length) {
                    return Text(
                      'D${value.toInt() + 1}',
                      style: const TextStyle(fontSize: 12),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 12),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (last7Days.length - 1).toDouble(),
          minY: 0,
          maxY: 10,
          lineBarsData: [
            // Hunger
            LineChartBarData(
              spots: last7Days.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value.hunger.toDouble());
              }).toList(),
              isCurved: true,
              color: Colors.orange,
              barWidth: 3,
              dotData: const FlDotData(show: true),
            ),
            // Hydration
            LineChartBarData(
              spots: last7Days.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value.hydration.toDouble());
              }).toList(),
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              dotData: const FlDotData(show: true),
            ),
            // Sleep
            LineChartBarData(
              spots: last7Days.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value.sleep.toDouble());
              }).toList(),
              isCurved: true,
              color: Colors.purple,
              barWidth: 3,
              dotData: const FlDotData(show: true),
            ),
            // Energy
            LineChartBarData(
              spots: last7Days.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value.energy.toDouble());
              }).toList(),
              isCurved: true,
              color: Colors.green,
              barWidth: 3,
              dotData: const FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodCard(MoodState mood) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text(
            mood.getMoodEmoji(),
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mood.getMoodLabel(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (mood.date != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${mood.date!.day}/${mood.date!.month}/${mood.date!.year}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBiologicalCard(BiologicalFunctions bio) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (bio.date != null)
            Text(
              '${bio.date!.day}/${bio.date!.month}/${bio.date!.year}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBioMetric('🍽️', 'Hunger', bio.hunger),
              _buildBioMetric('💧', 'Hydration', bio.hydration),
              _buildBioMetric('😴', 'Sleep', bio.sleep),
              _buildBioMetric('⚡', 'Energy', bio.energy),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBioMetric(String emoji, String label, int value) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

