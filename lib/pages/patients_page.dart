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
      final lastConsult = patient['lastConsultation'];
      final dateStr = lastConsult != null ? lastConsult['startDate'] : null;

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

  String _formatCpf(String rawCpf) {
    if (rawCpf.length != 11) return rawCpf;
    return '${rawCpf.substring(0, 3)}.${rawCpf.substring(3, 6)}.${rawCpf.substring(6, 9)}-${rawCpf.substring(9)}';
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
                                final cpf = patient['cpf'] ?? '---';
                                String lastConsultStr = '---';

                                // Agora pegamos diretamente a última consulta
                                final lastConsult = patient['lastConsultation'];

                                if (lastConsult != null) {
                                  final lastDate = DateTime.tryParse(
                                    lastConsult['startDate'],
                                  );
                                  if (lastDate != null) {
                                    lastConsultStr =
                                        '${lastDate.day.toString().padLeft(2, '0')}/${lastDate.month.toString().padLeft(2, '0')}/${lastDate.year}';
                                  }
                                }

                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4,
                                    horizontal: 4,
                                  ),
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
                                            230,
                                            230,
                                            230,
                                          ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Nome
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const Divider(height: 10),

                                        // Linha 1: Email (esquerda) e CPF (direita)
                                        Row(
                                          children: [
                                            const Text('Email: '),
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () {
                                                  showDialog(
                                                    context: context,
                                                    builder:
                                                        (_) => AlertDialog(
                                                          title: const Text(
                                                            'Email completo',
                                                          ),
                                                          content:
                                                              SelectableText(
                                                                email,
                                                              ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed:
                                                                  () =>
                                                                      Navigator.pop(
                                                                        context,
                                                                      ),
                                                              child: const Text(
                                                                'Fechar',
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                  );
                                                },
                                                child: Align(
                                                  alignment:
                                                      Alignment
                                                          .centerLeft, // alinha o Tooltip à esquerda
                                                  child: Tooltip(
                                                    message: email,
                                                    preferBelow:
                                                        false,
                                                    child: Text(
                                                      email,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      softWrap: false,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text('CPF: ${_formatCpf(cpf)}'),
                                          ],
                                        ),

                                        const SizedBox(height: 4),

                                        // Linha 2: Telefone (esquerda) e Última consulta (direita)
                                        Row(
                                          children: [
                                            Expanded(
                                              child: SelectableText(
                                                'Telefone: $phone',
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Última consulta: $lastConsultStr',
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 4),

                                        // Botão "Abrir Detalhes"
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton(
                                            onPressed: () {
                                              // abrir detalhes
                                            },
                                            child: const Text('Abrir Detalhes'),
                                          ),
                                        ),
                                      ],
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
