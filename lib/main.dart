import 'package:flutter/material.dart';

import 'pages/login_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/settings_page.dart';
import 'pages/patients_page.dart';
import 'pages/consultations_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CareBaseApp());
}

class CareBaseApp extends StatelessWidget {
  const CareBaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CareBase',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData.dark(),
      initialRoute: '/login',  // <-- login primeiro
      routes: {
        '/login': (context) => const LoginPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/config': (context) => const SettingsPage(),
        '/pacientes': (context) => const PatientsPage(),
        '/consultas': (context) => const ConsultationsPage(),
      },
    );
  }
}
