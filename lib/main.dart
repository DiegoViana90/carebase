import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/theme_provider.dart';

import 'pages/auth_check_page.dart'; // NOVO
import 'pages/login_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/settings_page.dart';
import 'pages/patients_page.dart';
import 'pages/consultations_page.dart';
import 'pages/finance_page.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const CareBaseApp(),
    ),
  );
}

class CareBaseApp extends StatelessWidget {
  const CareBaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'CareBase',
      themeMode: themeProvider.isDark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData.dark(),
      initialRoute: '/', // <- MUDADO AQUI
      routes: {
        '/': (context) => const AuthCheckPage(), // <- ADICIONADO
        '/login': (context) => const LoginPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/config': (context) => const SettingsPage(),
        '/pacientes': (context) => const PatientsPage(),
        '/consultas': (context) => const ConsultationsPage(),
        '/financeiro': (context) => const FinancePage(),
      },
    );
  }
}
