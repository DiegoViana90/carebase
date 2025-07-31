import 'package:flutter/material.dart';

class PatientsPage extends StatelessWidget {
  const PatientsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pacientes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Adicionar Paciente',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const AddPatientDialog(),
              );
            },
          )
        ],
      ),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: PatientsGrid(),
      ),
    );
  }
}

class PatientsGrid extends StatelessWidget {
  final List<Map<String, String>> patients = const []; // Lista mock

  const PatientsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    if (patients.isEmpty) {
      return const Center(
        child: Text('Nenhum paciente cadastrado.'),
      );
    }

    return ListView.builder(
      itemCount: patients.length,
      itemBuilder: (context, index) {
        final patient = patients[index];
        return Card(
          child: ListTile(
            title: Text(patient['name'] ?? ''),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Telefone: ${patient['phone'] ?? ''}'),
                Text('Email: ${patient['email'] ?? ''}'),
                Text('Última consulta: ${patient['lastConsult'] ?? ''}'),
              ],
            ),
            trailing: TextButton(
              onPressed: () {
                // Navegar para detalhes (em breve)
              },
              child: const Text('Abrir Detalhes'),
            ),
          ),
        );
      },
    );
  }
}

class AddPatientDialog extends StatelessWidget {
  const AddPatientDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adicionar Paciente'),
      content: const Text('Formulário virá aqui futuramente...'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}
