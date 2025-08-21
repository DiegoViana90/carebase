import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:carebase/core/services/consultation_service.dart';

class PatientConsultationsModal extends StatefulWidget {
  final int patientId;
  final String patientName;

  const PatientConsultationsModal({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<PatientConsultationsModal> createState() => _PatientConsultationsModalState();
}

class _PatientConsultationsModalState extends State<PatientConsultationsModal> {
  List<Map<String, dynamic>> consultations = [];
  double totalSpent = 0;
  double totalPending = 0;
  bool isLoading = true;
  String? errorMessage;

  // Formatadores
  final _date = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');
  final _money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    _loadConsultations();
  }

  // Helpers de parsing/format
  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    try {
      // Se o backend mandar sem offset, o Dart interpreta como hora local.
      return DateTime.parse(v.toString());
    } catch (_) {
      return null;
    }
  }

  String _formatRange(Map<String, dynamic> c) {
    final a = _parseDate(c['startDate']);
    final b = _parseDate(c['endDate']);
    if (a == null) return '—';
    if (b == null) return _date.format(a);
    return '${_date.format(a)} – ${_date.format(b)}';
  }

  num _asNum(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v;
    if (v is String) return num.tryParse(v.replaceAll(',', '.')) ?? 0;
    return 0;
  }

  Future<void> _loadConsultations() async {
    try {
      final data = await ConsultationService.fetchConsultationsByPatient(widget.patientId);

      // Ordena por data (mais recentes primeiro)
      data.sort((a, b) {
        final ad = _parseDate(a['startDate']) ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = _parseDate(b['startDate']) ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });

      setState(() {
        consultations = data;
        totalSpent = _calculateTotal(data);
        totalPending = _calculatePending(data);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  // Tenta usar campos se existirem; senão, 0 (seu JSON atual não tem valores)
  double _calculateTotal(List<Map<String, dynamic>> data) {
    return data.fold<double>(0, (sum, c) {
      // tenta totalValue/amount/value
      final total = _asNum(c['totalValue'] ?? c['amount'] ?? c['value']);
      return sum + total.toDouble();
    });
  }

  double _calculatePending(List<Map<String, dynamic>> data) {
    return data.fold<double>(0, (sum, c) {
      if (c['pendingAmount'] != null) {
        return sum + _asNum(c['pendingAmount']).toDouble();
      }
      // fallback: total - pago (se existirem)
      final total = _asNum(c['totalValue'] ?? c['amount'] ?? c['value']);
      final paid = _asNum(c['amountPaid'] ?? c['paid']);
      final pend = (total - paid).toDouble();
      return sum + (pend.isFinite ? (pend < 0 ? 0 : pend) : 0);
    });
  }

  String _statusLabel(dynamic status) {
    switch (status) {
      case 0:
        return 'Agendada';
      case 1:
        return 'Concluída';
      case 2:
        return 'Cancelada';
      case 3:
        return 'Faltou';
      default:
        return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Consultas de ${widget.patientName}',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),

            // Corpo
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : errorMessage != null
                      ? Center(child: Text(errorMessage!))
                      : consultations.isEmpty
                          ? const Center(child: Text('Nenhuma consulta disponível ainda.'))
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              itemCount: consultations.length,
                              separatorBuilder: (_, __) => const Divider(),
                              itemBuilder: (_, i) {
                                final c = consultations[i];

                                final id = c['consultationId'] ?? c['id'] ?? '—';
                                final whenText = _formatRange(c);
                                // Mostra algum valor se existir; se não, será 0
                                final lineValue = _asNum(c['totalValue'] ?? c['amount'] ?? c['value']);
                                final statusText = _statusLabel(c['status']);

                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Chip(
                                    label: Text(statusText),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  title: Text('Consulta #$id'),
                                  subtitle: Text('Data: $whenText'),
                                  trailing: Text(_money.format(lineValue)),
                                );
                              },
                            ),
            ),

            // Rodapé (Total + Pendências + Fechar)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Expanded(child: Text('Total gasto: ${_money.format(totalSpent)}')),
                  Expanded(child: Text('Pendências: ${_money.format(totalPending)}')),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Fechar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
