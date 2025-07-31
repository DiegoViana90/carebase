import 'package:flutter/material.dart';

class ConsultationsPage extends StatelessWidget {
  const ConsultationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultas'),
      ),
      body: const Center(
        child: Text('Aqui será a lista/agendamento de consultas.'),
      ),
    );
  }
}
