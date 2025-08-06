import 'dart:async';
import 'package:carebase/core/services/consultation_service.dart';
import 'package:carebase/core/services/patient_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ConfirmConsultationModal extends StatefulWidget {
  final List<TimeOfDay> selectedTimes;
  final List<TimeOfDay> availableTimes;
  final DateTime date;

  const ConfirmConsultationModal({
    super.key,
    required this.selectedTimes,
    required this.availableTimes,
    required this.date,
  });

  @override
  State<ConfirmConsultationModal> createState() =>
      _ConfirmConsultationModalState();
}

class _ConfirmConsultationModalState extends State<ConfirmConsultationModal> {
  final _formKey = GlobalKey<FormState>();
  String nameOrCpf = '';
  bool isLoading = false;
  Map<String, dynamic>? patientData;
  String? errorMessage;
  bool confirmEnabled = false;

  Future<void> _searchPatient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      patientData = null;
      errorMessage = null;
      confirmEnabled = false;
    });

    try {
      final result = await PatientService.fetchPatientByCpf(nameOrCpf);
      setState(() {
        patientData = result;
        if (result == null) {
          errorMessage = 'Paciente não encontrado.';
        } else {
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() => confirmEnabled = true);
            }
          });
        }
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Retorna o horário da grade que vem após o último selecionado
  TimeOfDay? _getNextTimeSlot() {
    final last = widget.selectedTimes.last;
    final index = widget.availableTimes.indexWhere(
      (t) => t.hour == last.hour && t.minute == last.minute,
    );

    if (index >= 0 && index < widget.availableTimes.length - 1) {
      return widget.availableTimes[index + 1];
    }

    return null;
  }

  void _showFinalConfirmation() {
    final name = patientData!['name'] ?? 'Sem nome';
    final cpf = patientData!['cpf'] ?? '';
    final formattedDate = DateFormat('dd/MM/yyyy').format(widget.date);

    final start = widget.selectedTimes.first;
    final nextSlot = _getNextTimeSlot();
    final startStr = start.format(context);
    final timeRange =
        nextSlot != null
            ? 'das $startStr até ${nextSlot.format(context)}'
            : 'às $startStr';

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Confirmar agendamento'),
            content: Text(
              'Deseja agendar o paciente $name,\n'
              'CPF: $cpf\n'
              'para $formattedDate $timeRange?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context); // Fecha o ConfirmConsultationModal

                  final first = widget.selectedTimes.first;
                  final last = widget.selectedTimes.last;

                  final startDate =
                      DateTime(
                        widget.date.year,
                        widget.date.month,
                        widget.date.day,
                        first.hour,
                        first.minute,
                      ).toLocal(); // 👈 Aplicando timezone local

                  final endDate =
                      DateTime(
                            widget.date.year,
                            widget.date.month,
                            widget.date.day,
                            last.hour,
                            last.minute,
                          )
                          .add(const Duration(minutes: 30))
                          .toLocal(); // 👈 +30min e local

                  try {
                    await ConsultationService.createConsultation(
                      patientId: patientData!['patientId'],
                      startDate: startDate,
                      endDate: endDate,
                    );

                    if (mounted) {
                      Navigator.of(
                        context,
                      ).pop(); // Fecha o ConfirmConsultationModal
                      Navigator.of(context).pop(
                        true,
                      ); // Fecha o ScheduleConsultationModal e sinaliza sucesso

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Consulta agendada com sucesso!'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      Navigator.of(
                        context,
                      ).pop(); // Fecha o ConfirmConsultationModal
                      Navigator.of(
                        context,
                      ).pop(); // Fecha o ScheduleConsultationModal (sem sucesso)

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erro ao agendar consulta: $e')),
                      );
                    }
                  }
                },
                child: const Text('Agendar'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd/MM/yyyy').format(widget.date);

    return AlertDialog(
      title: Text('Agendar para $formattedDate'),
      content: SizedBox(
        width: 320,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'CPF do paciente',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => nameOrCpf = value.trim(),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o CPF do paciente';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (isLoading) const CircularProgressIndicator(),
              if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              if (patientData != null) ...[
                const Divider(height: 24),
                ListTile(
                  title: Text(
                    patientData!['name'] ?? 'Sem nome',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    patientData!['cpf'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed:
              isLoading
                  ? null
                  : patientData != null
                  ? (confirmEnabled ? _showFinalConfirmation : null)
                  : _searchPatient,
          icon: Icon(patientData != null ? Icons.check : Icons.search),
          label: Text(
            patientData != null ? 'Confirmar Agendamento' : 'Buscar Paciente',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                patientData != null && !confirmEnabled ? Colors.grey : null,
          ),
        ),
      ],
    );
  }
}
