// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trying_flutter/providers/medication_provider.dart';
import 'package:trying_flutter/providers/patient_report_provider.dart';
import 'package:trying_flutter/providers/session_provider.dart';
import 'package:trying_flutter/providers/task_provider.dart';
import 'package:trying_flutter/providers/analytics_provider.dart';
import 'package:trying_flutter/providers/professional_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MedicationProvider()),
        ChangeNotifierProvider(create: (_) => PatientReportProvider()),
        ChangeNotifierProvider(create: (_) => SessionProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
        ChangeNotifierProvider(create: (_) => ProfessionalProvider()),
      ],
      child: MaterialApp(
        title: 'PsyMed',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const LoginScreen(),
      ),
    );
  }
}