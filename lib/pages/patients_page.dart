import 'package:flutter/material.dart';
import 'package:carebase/utils/base_page_layout.dart';

class PatientsPage extends StatefulWidget {
  const PatientsPage({super.key});

  @override
  State<PatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends State<PatientsPage> {
  final List<Map<String, dynamic>> allPatients = [
    {
      'name': 'Ana Souza',
      'phone': '(11) 91234-5678',
      'email': 'ana@email.com',
      'lastConsult': DateTime(2025, 7, 15),
    },
    {
      'name': 'Carlos Lima',
      'phone': '(21) 99876-5432',
      'email': 'carlos@email.com',
      'lastConsult': DateTime(2025, 7, 3),
    },
    {
      'name': 'Mariana Silva',
      'phone': '(31) 99888-7766',
      'email': 'mariana@email.com',
      'lastConsult': DateTime(2025, 6, 20),
    },
  ];

  String searchName = '';
  String filterDate = 'Todas';

  List<Map<String, dynamic>> get filteredPatients {
    final now = DateTime.now();

    return allPatients.where((patient) {
      final matchesName = patient['name']
          .toLowerCase()
          .contains(searchName.toLowerCase());

      bool matchesDate = true;
      if (filterDate == 'Última Semana') {
        matchesDate = patient['lastConsult']
            .isAfter(now.subtract(const Duration(days: 7)));
      } else if (filterDate == 'Último Mês') {
        matchesDate = patient['lastConsult']
            .isAfter(DateTime(now.year, now.month - 1, now.day));
      }

      return matchesName && matchesDate;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BasePageLayout(
      title: 'Pacientes',
      showBackButton: false, // Usa o drawer
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Buscar por nome',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchName = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: DropdownButton<String>(
                  value: filterDate,
                  underline: const SizedBox(),
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'Todas', child: Text('Todas')),
                    DropdownMenuItem(value: 'Última Semana', child: Text('Última Semana')),
                    DropdownMenuItem(value: 'Último Mês', child: Text('Último Mês')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      filterDate = value ?? 'Todas';
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: filteredPatients.isEmpty
                ? const Center(child: Text('Nenhum paciente encontrado.'))
                : ListView.builder(
                    itemCount: filteredPatients.length,
                    itemBuilder: (context, index) {
                      final patient = filteredPatients[index];
                      final lastConsultStr =
                          '${patient['lastConsult'].day.toString().padLeft(2, '0')}/'
                          '${patient['lastConsult'].month.toString().padLeft(2, '0')}/'
                          '${patient['lastConsult'].year}';

                      return Card(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color.fromARGB(255, 44, 44, 44)
                            : const Color.fromARGB(255, 209, 209, 209),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          title: Text(patient['name']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Telefone: ${patient['phone']}'),
                              Text('Email: ${patient['email']}'),
                              Text('Última consulta: $lastConsultStr'),
                            ],
                          ),
                          trailing: TextButton(
                            onPressed: () {
                              // abrir detalhes
                            },
                            child: const Text('Abrir Detalhes'),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const AddPatientDialog(),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Adicionar Paciente'),
          ),
        ],
      ),
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
