import 'package:carebase/core/services/consultation_service.dart';
import 'package:carebase/enums/consult_status.dart';
import 'package:carebase/enums/payment_method.dart';
import 'payment_method_dialog.dart' show PaymentMethodDialog, PaymentLine;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ViewConsultationModal extends StatefulWidget {
  final int consultationId;
  final String patient;
  final DateTime start;
  final DateTime end;

  final String? titulo1;
  final String? titulo2;
  final String? titulo3;

  final String? texto1;
  final String? texto2;
  final String? texto3;
  final double? amountPaid;
  final int? statusIndex;
  final List<PaymentLine>? initialPayments;

  const ViewConsultationModal({
    super.key,
    required this.consultationId,
    required this.patient,
    required this.start,
    required this.end,
    this.titulo1,
    this.titulo2,
    this.titulo3,
    this.texto1,
    this.texto2,
    this.texto3,
    this.amountPaid,
    this.statusIndex,
    this.initialPayments, // <-- ADICIONE AQUI
  });

  @override
  State<ViewConsultationModal> createState() => _ViewConsultationModalState();
}

class _ViewConsultationModalState extends State<ViewConsultationModal> {
  late final TextEditingController _titulo1Ctrl;
  late final TextEditingController _titulo2Ctrl;
  late final TextEditingController _titulo3Ctrl;

  late final TextEditingController _texto1Ctrl;
  late final TextEditingController _texto2Ctrl;
  late final TextEditingController _texto3Ctrl;
  final TextEditingController _paidAmountCtrl = TextEditingController();

  // pagamento
  List<PaymentLine> _paymentLines = [];
  PaymentMethod?
  _paymentMethod; // método da 1ª linha (apenas para exibir chip antigo)

  ConsultStatus? _status;

  final NumberFormat _money = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: '',
    decimalDigits: 2,
  );

  double _totalPayments() =>
      _paymentLines.fold<double>(0.0, (sum, l) => sum + l.amount);

  void _applyPaymentsToUI() {
    _paidAmountCtrl.text = _money.format(_totalPayments());
    _paymentMethod =
        _paymentLines.isNotEmpty ? _paymentLines.first.method : null;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    _titulo1Ctrl = TextEditingController(
      text: widget.titulo1 ?? 'Ficha de Anamnese',
    );
    _titulo2Ctrl = TextEditingController(
      text: widget.titulo2 ?? 'Procedimentos Realizados',
    );
    _titulo3Ctrl = TextEditingController(
      text: widget.titulo3 ?? 'Mais Informações',
    );

    _texto1Ctrl = TextEditingController(text: widget.texto1 ?? '');
    _texto2Ctrl = TextEditingController(text: widget.texto2 ?? '');
    _texto3Ctrl = TextEditingController(text: widget.texto3 ?? '');

    final amount = widget.amountPaid;
    if (amount != null) {
      _paidAmountCtrl.text = _money.format(amount);
    }

    final statusIndex = widget.statusIndex;
    if (statusIndex != null) {
      _status = ConsultStatus.values.firstWhere(
        (s) => s.index == statusIndex,
        orElse: () => ConsultStatus.agendado,
      );
    }
    
    if (widget.initialPayments != null && widget.initialPayments!.isNotEmpty) {
      _paymentLines = List<PaymentLine>.from(widget.initialPayments!);
      _applyPaymentsToUI(); // atualiza Total (calc.) e chip do método
    }
  }

  @override
  void dispose() {
    _titulo1Ctrl.dispose();
    _titulo2Ctrl.dispose();
    _titulo3Ctrl.dispose();
    _texto1Ctrl.dispose();
    _texto2Ctrl.dispose();
    _texto3Ctrl.dispose();
    _paidAmountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.85,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Detalhes da Consulta',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('Paciente: ${widget.patient}'),
              Text('Início: ${formatter.format(widget.start)}'),
              Text('Término: ${formatter.format(widget.end)}'),
              const SizedBox(height: 16),

              // Linha com Status, Total (somente leitura) e botão de pagamentos
              Row(
                children: [
                  // STATUS
                  Expanded(
                    child: DropdownButtonFormField<ConsultStatus>(
                      value: _status == ConsultStatus.agendado ? null : _status,
                      onChanged: (value) => setState(() => _status = value),
                      decoration: const InputDecoration(
                        labelText: 'Status da consulta',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      hint: const Text('Agendado'),
                      items:
                          ConsultStatus.values
                              .where((s) => s != ConsultStatus.agendado)
                              .map(
                                (status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(_statusLabel(status)),
                                ),
                              )
                              .toList(),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // TOTAL calculado (somente leitura)
                  SizedBox(
                    width: 140,
                    child: TextFormField(
                      controller: _paidAmountCtrl,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Total (calc.)',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // BOTÃO que abre o dialog de pagamentos
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: IconButton(
                      tooltip: 'Pagamento (múltiplas linhas)',
                      onPressed: () async {
                        final lines = await showDialog<List<PaymentLine>>(
                          context: context,
                          builder:
                              (_) => PaymentMethodDialog(
                                initialLines: _paymentLines,
                              ),
                        );
                        if (lines != null) {
                          _paymentLines = lines;
                          _applyPaymentsToUI();
                        }
                      },
                      icon: const Icon(Icons.payment, size: 20),
                      style: IconButton.styleFrom(
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                ],
              ),

              if (_paymentMethod != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(_paymentMethod!.label),
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Blocos editáveis
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildEditableBlock(_titulo1Ctrl, _texto1Ctrl),
                      const SizedBox(height: 20),
                      _buildEditableBlock(_titulo2Ctrl, _texto2Ctrl),
                      const SizedBox(height: 20),
                      _buildEditableBlock(_titulo3Ctrl, _texto3Ctrl),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),

              // Ações
              Align(
                alignment: Alignment.bottomRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Fechar'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder:
                                (_) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                          );

                          // 1) salva detalhes/status (sem valor/método)
                          await ConsultationService.updateConsultationDetails(
                            consultationId: widget.consultationId,
                            titulo1: _titulo1Ctrl.text.trim(),
                            titulo2: _titulo2Ctrl.text.trim(),
                            titulo3: _titulo3Ctrl.text.trim(),
                            texto1: _texto1Ctrl.text.trim(),
                            texto2: _texto2Ctrl.text.trim(),
                            texto3: _texto3Ctrl.text.trim(),
                            status: _status?.name,
                          );

                          if (_paymentLines.isNotEmpty) {
                            await ConsultationService.createPayments(
                              consultationId: widget.consultationId,
                              lines:
                                  _paymentLines
                                      .map(
                                        (l) => {
                                          'method':
                                              l
                                                  .method
                                                  .index, // 👈 envia como int
                                          'installments': l.installments,
                                          'amount': l.amount,
                                        },
                                      )
                                      .toList(),
                            );
                          }

                          Navigator.pop(context); // fecha loader
                          Navigator.pop(context, true); // fecha modal
                        } catch (e) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erro ao salvar: $e')),
                          );
                        }
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('Salvar'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditableBlock(
    TextEditingController titleCtrl,
    TextEditingController contentCtrl,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final contentTextColor = isDark ? Colors.black87 : null;
    final hintTextColor = isDark ? Colors.grey[600] : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: titleCtrl,
            maxLength: 100,
            decoration: const InputDecoration(
              hintText: 'Título da seção',
              border: UnderlineInputBorder(),
              isDense: true,
              counterText: '',
            ),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                height: 160,
                child: TextField(
                  controller: contentCtrl,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: TextStyle(color: contentTextColor),
                  decoration: InputDecoration.collapsed(
                    hintText: 'Escreva aqui...',
                    hintStyle: TextStyle(color: hintTextColor),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(ConsultStatus status) {
    switch (status) {
      case ConsultStatus.agendado:
        return 'Agendado';
      case ConsultStatus.compareceu:
        return 'Compareceu';
      case ConsultStatus.naoCompareceu:
        return 'Não compareceu';
      case ConsultStatus.reagendado:
        return 'Reagendado';
    }
  }
}
