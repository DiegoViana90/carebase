import 'package:flutter/material.dart';
import 'package:carebase/utils/base_page_layout.dart';
import 'package:carebase/core/services/patient_service.dart';
import 'package:carebase/pages/add_patient_page.dart';

class PatientsPage extends StatefulWidget {
  const PatientsPage({super.key});

  @override
  State<PatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends State<PatientsPage> {
  List<Map<String, dynamic>> allPatients = [];
  String searchName = '';
  String filterDate = 'Todas';
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  Future<void> _fetchPatients() async {
    try {
      final data = await PatientService.fetchAllPatients();
      await Future.delayed(const Duration(seconds: 1)); // Força mínimo de 1s

      setState(() {
        allPatients = data;
        isLoading = false;
      });
    } catch (e) {
      await Future.delayed(const Duration(seconds: 1)); // Mesmo no erro

      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get filteredPatients {
    final now = DateTime.now();

    return allPatients.where((patient) {
      final name = (patient['name'] ?? '').toLowerCase();
      final matchesName = name.contains(searchName.toLowerCase());

      bool matchesDate = true;
      final dateStr = patient['lastConsultationDate'];
      if (filterDate != 'Todas' && dateStr != null) {
        final consultDate = DateTime.tryParse(dateStr);
        if (consultDate != null) {
          if (filterDate == 'Última Semana') {
            matchesDate = consultDate.isAfter(
              now.subtract(const Duration(days: 7)),
            );
          } else if (filterDate == 'Último Mês') {
            matchesDate = consultDate.isAfter(
              DateTime(now.year, now.month - 1, now.day),
            );
          }
        } else {
          matchesDate = false;
        }
      }

      return matchesName && matchesDate;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BasePageLayout(
      title: 'Pacientes',
      showBackButton: false,
      child:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : error != null
              ? Center(child: Text(error!))
              : Column(
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
                            DropdownMenuItem(
                              value: 'Todas',
                              child: Text('Todas'),
                            ),
                            DropdownMenuItem(
                              value: 'Última Semana',
                              child: Text('Última Semana'),
                            ),
                            DropdownMenuItem(
                              value: 'Último Mês',
                              child: Text('Último Mês'),
                            ),
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
                    child:
                        filteredPatients.isEmpty
                            ? const Center(
                              child: Text('Nenhum paciente encontrado.'),
                            )
                            : ListView.builder(
                              itemCount: filteredPatients.length,
                              itemBuilder: (context, index) {
                                final patient = filteredPatients[index];

                                final name = patient['name'] ?? 'Sem nome';
                                final phone = patient['phone'] ?? '---';
                                final email = patient['email'] ?? '---';
                                final dateStr = patient['lastConsultationDate'];
                                String lastConsultStr = '---';

                                if (dateStr != null) {
                                  final dt = DateTime.tryParse(dateStr);
                                  if (dt != null) {
                                    lastConsultStr =
                                        '${dt.day.toString().padLeft(2, '0')}/'
                                        '${dt.month.toString().padLeft(2, '0')}/'
                                        '${dt.year}';
                                  }
                                }

                                return Card(
                                  color:
                                      Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? const Color.fromARGB(
                                            255,
                                            44,
                                            44,
                                            44,
                                          )
                                          : const Color.fromARGB(
                                            255,
                                            209,
                                            209,
                                            209,
                                          ),
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  child: ListTile(
                                    title: Text(name),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Telefone: $phone'),
                                        Text('Email: $email'),
                                        Text(
                                          'Última consulta: $lastConsultStr',
                                        ),
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
                        builder:
                            (_) => AddPatientModal(onSuccess: _fetchPatients),
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
