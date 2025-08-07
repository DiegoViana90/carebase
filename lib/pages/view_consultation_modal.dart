import 'package:carebase/core/services/consultation_service.dart';
import 'package:carebase/enums/consult_status.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

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
  final double? amountPaid; // 👈 nov
  final int? statusIndex; // 👈 novo

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
    this.amountPaid,     // 👈 novo
    this.statusIndex,  
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
  double _getNumericValue(String value) {
    final cleaned = value.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(cleaned) ?? 0.0;
  }

  ConsultStatus? _status;

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

    // ✅ Se vier valor, preencher no campo de pagamento
    final amount = widget.amountPaid;
    if (amount != null) {
      final formatter = NumberFormat.currency(
        locale: 'pt_BR',
        symbol: '',
        decimalDigits: 2,
      );
      _paidAmountCtrl.text = formatter.format(amount);
    }

    // ✅ Se vier status numérico, converter em enum
    final statusIndex = widget.statusIndex;
    if (statusIndex != null) {
      _status = ConsultStatus.values.firstWhere(
        (s) => s.index == statusIndex,
        orElse: () => ConsultStatus.agendado,
      );
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

              // 👇 Status + Valor pago
              Row(
                children: [
                  SizedBox(
                    width: 200,
                    child: DropdownButtonFormField<ConsultStatus>(
                      value: _status == ConsultStatus.agendado ? null : _status,
                      onChanged: (value) {
                        setState(() {
                          _status = value;
                        });
                      },
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
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 120,
                    child: TextFormField(
                      controller: _paidAmountCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [_currencyFormatter],
                      decoration: const InputDecoration(
                        labelText: 'R\$ Pago',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

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

              // Botões
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

                          // Atualiza os detalhes (detalhes da seção)
                          await ConsultationService.updateConsultationDetails(
                            consultationId: widget.consultationId,
                            titulo1: _titulo1Ctrl.text.trim(),
                            titulo2: _titulo2Ctrl.text.trim(),
                            titulo3: _titulo3Ctrl.text.trim(),
                            texto1: _texto1Ctrl.text.trim(),
                            texto2: _texto2Ctrl.text.trim(),
                            texto3: _texto3Ctrl.text.trim(),
                            amountPaid: _getNumericValue(_paidAmountCtrl.text),
                            status: _status?.name,
                          );

                          Navigator.pop(context); // fecha loader
                          Navigator.pop(context, true); // fecha modal
                        } catch (e) {
                          Navigator.pop(context); // fecha loader
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
                  decoration: const InputDecoration.collapsed(
                    hintText: 'Escreva aqui...',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  final _currencyFormatter = TextInputFormatter.withFunction((
    oldValue,
    newValue,
  ) {
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (newText.isEmpty) return newValue.copyWith(text: '');

    // Limita o número de dígitos a 7 (9999999 centavos = 99999,99 reais)
    if (newText.length > 7) {
      newText = newText.substring(0, 7);
    }

    final number = double.parse(newText) / 100;
    final formatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: '',
      decimalDigits: 2,
    );
    final newString = formatter.format(number);

    return TextEditingValue(
      text: newString,
      selection: TextSelection.collapsed(offset: newString.length),
    );
  });

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
