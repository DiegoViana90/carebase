import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'pages/dashboard_page.dart';
import 'pages/settings_page.dart';
import 'core/theme/theme_provider.dart';

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
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData.dark(),
      initialRoute: '/',
      routes: {
        '/': (context) => const DashboardPage(),
        '/config': (context) => const SettingsPage(),
        // outras rotas futuras: /pacientes, /consultas, /financeiro
      },
    );
  }
}
