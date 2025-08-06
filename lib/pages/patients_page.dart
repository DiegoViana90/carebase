import 'package:flutter/material.dart';
import 'package:carebase/utils/base_page_layout.dart';
import 'package:carebase/core/services/patient_service.dart';
import 'package:carebase/pages/add_patient_page.dart';
import 'package:flutter/services.dart';

class PatientsPage extends StatefulWidget {
  const PatientsPage({super.key});

  @override
  State<PatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends State<PatientsPage> {
  List<Map<String, dynamic>> allPatients = [];
  String searchName = '';
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
    return allPatients.where((patient) {
      final name = (patient['name'] ?? '').toLowerCase();
      final email = (patient['email'] ?? '').toLowerCase();
      final query = searchName.toLowerCase();

      return name.contains(query) || email.contains(query);
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
                            labelText: 'Buscar por nome ou email',
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: (value) {
                            setState(() {
                              searchName = value;
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
                                        // Linha 1: Email (esquerda) e CPF (direita)
                                        Row(
                                          children: [
                                            const Text('Email: '),
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () {
                                                  Clipboard.setData(
                                                    ClipboardData(text: email),
                                                  );
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'Email copiado: $email',
                                                      ),
                                                      duration: const Duration(
                                                        seconds: 2,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                child: Tooltip(
                                                  message: 'Clique para copiar',
                                                  preferBelow: false,
                                                  child: Text(
                                                    email,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    softWrap: false,
                                                    style: const TextStyle(
                                                      decoration:
                                                          TextDecoration
                                                              .underline,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            GestureDetector(
                                              onTap: () {
                                                Clipboard.setData(
                                                  ClipboardData(
                                                    text: _formatCpf(cpf),
                                                  ),
                                                );
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'CPF copiado: ${_formatCpf(cpf)}',
                                                    ),
                                                    duration: const Duration(
                                                      seconds: 2,
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Tooltip(
                                                message: 'Clique para copiar',
                                                child: Text(
                                                  'CPF: ${_formatCpf(cpf)}',
                                                  style: const TextStyle(
                                                    decoration:
                                                        TextDecoration
                                                            .underline,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 4),

                                        // Linha 2: Telefone (esquerda) e Última consulta (direita)
                                        Row(
                                          children: [
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () {
                                                  Clipboard.setData(
                                                    ClipboardData(text: phone),
                                                  );
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'Telefone copiado: $phone',
                                                      ),
                                                      duration: const Duration(
                                                        seconds: 2,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                child: Tooltip(
                                                  message: 'Clique para copiar',
                                                  child: Text(
                                                    'Telefone: $phone',
                                                    style: const TextStyle(
                                                      decoration:
                                                          TextDecoration
                                                              .underline,
                                                    ),
                                                  ),
                                                ),
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
