import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:carebase/core/services/consultation_service.dart';
import 'package:carebase/ui/status_tag.dart';

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
  final _day = DateFormat('dd/MM/yy', 'pt_BR');
  final _hm  = DateFormat('HH:mm', 'pt_BR');
  final _money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    _loadConsultations();
  }

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }

  // Exibe em duas linhas:
  // Data: 09/08/25
  //           10:00 – 11:00
  String _formatDayAndTimes(Map<String, dynamic> c) {
    final a = _parseDate(c['startDate']);
    final b = _parseDate(c['endDate']);
    if (a == null) return 'Data: —';

    final dia = _day.format(a);
    String linha2;
    if (b == null) {
      linha2 = _hm.format(a);
    } else if (a.year == b.year && a.month == b.month && a.day == b.day) {
      linha2 = '${_hm.format(a)} – ${_hm.format(b)}';
    } else {
      linha2 = '${_hm.format(a)} – ${_day.format(b)} ${_hm.format(b)}';
    }
    return 'Data: $dia\n          $linha2';
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

  double _calculateTotal(List<Map<String, dynamic>> data) {
    return data.fold<double>(0, (sum, c) {
      final total = _asNum(c['totalValue'] ?? c['amount'] ?? c['value']);
      return sum + total.toDouble();
    });
  }

  double _calculatePending(List<Map<String, dynamic>> data) {
    return data.fold<double>(0, (sum, c) {
      if (c['pendingAmount'] != null) {
        return sum + _asNum(c['pendingAmount']).toDouble();
      }
      final total = _asNum(c['totalValue'] ?? c['amount'] ?? c['value']);
      final paid = _asNum(c['amountPaid'] ?? c['paid']);
      final pend = (total - paid).toDouble();
      return sum + (pend.isFinite ? (pend < 0 ? 0 : pend) : 0);
    });
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
                                final whenText = _formatDayAndTimes(c);
                                final lineValue = _asNum(c['totalValue'] ?? c['amount'] ?? c['value']);
                                final status = c['status'] as int?;

                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: StatusTag(status: status, kind: StatusKind.consultation),
                                  title: Text('Consulta #$id'),
                                  subtitle: Text(whenText),
                                  trailing: Text(_money.format(lineValue)),
                                );
                              },
                            ),
            ),

            // Rodapé de totais (sem botão)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                // sem borda inferior aqui, pq virá a barra de ações abaixo
              ),
              child: Row(
                children: [
                  Expanded(child: Text('Total gasto: ${_money.format(totalSpent)}')),
                  Expanded(child: Text('Pendências: ${_money.format(totalPending)}')),
                ],
              ),
            ),

            // Barra de ações (apenas o Fechar), separada
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              decoration: const BoxDecoration(
                // deixa a curvatura final no container de ações
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
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
