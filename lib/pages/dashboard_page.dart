import 'package:flutter/material.dart';
import 'package:carebase/core/services/auth_service.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Confirmar saída'),
            content: const Text('Tem certeza que deseja sair da sua conta?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                child: const Text('Sair'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await AuthService.logout();
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CareBase – Gestão de Pacientes')),
      drawer: Drawer(
        child: Column(
          children: [
            // Cabeçalho compacto
            Container(
              height: 80,
              width: double.infinity,
              color: Colors.teal,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Text(
                'Menu Principal',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),

            // Lista principal
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Pacientes'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/pacientes');
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Consultas'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/consultas');
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: const Text('Financeiro'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/financeiro');
              },
            ),

            const Spacer(),

            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Configurações'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/config');
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sair'),
              onTap: () => _confirmLogout(context),
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
