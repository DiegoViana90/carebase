import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CareBase – Gestão de Pacientes'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.teal,
              ),
              child: Text(
                'Menu Principal',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Pacientes'),
              onTap: () {
                Navigator.pushNamed(context, '/pacientes');
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Consultas'),
              onTap: () {
                Navigator.pushNamed(context, '/consultas');
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: const Text('Financeiro'),
              onTap: () {
                Navigator.pushNamed(context, '/financeiro');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Configurações'),
              onTap: () {
                Navigator.pushNamed(context, '/config');
              },
            ),
          ],
        ),
      ),
      body: const Center(
        child: Text('Bem-vindo ao CareBase – Gestão de Pacientes!'),
      ),
    );
  }
}
