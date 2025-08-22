import 'package:carebase/pages/manage_installments_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:carebase/enums/payment_method.dart';
import 'package:carebase/models/payment_line.dart';

class PaymentMethodDialog extends StatefulWidget {
  final List<PaymentLine>? initialLines;

  const PaymentMethodDialog({super.key, this.initialLines});

  @override
  State<PaymentMethodDialog> createState() => _PaymentMethodDialogState();
}

class _PaymentMethodDialogState extends State<PaymentMethodDialog> {
  final _currencyFormatter = TextInputFormatter.withFunction((oldValue, newValue) {
    String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue(text: '');
    if (digits.length > 9) digits = digits.substring(0, 9);
    final value = double.parse(digits) / 100;
    final f = NumberFormat.currency(locale: 'pt_BR', symbol: '', decimalDigits: 2);
    final s = f.format(value);
    return TextEditingValue(
      text: s,
      selection: TextSelection.collapsed(offset: s.length),
    );
  });

  final _lines = <_EditableLine>[];
  bool _installmentsManaged = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLines?.isNotEmpty == true) {
      for (final l in widget.initialLines!) {
        final ctrl = _amountToCtrl(l.amount);
        ctrl.addListener(_onAmountChanged);
        _lines.add(_EditableLine(
          method: l.method,
          installments: l.installments,
          amountCtrl: ctrl,
          details: l.installmentsDetails,
        ));
      }
    } else {
      final ctrl = TextEditingController();
      ctrl.addListener(_onAmountChanged);
      _lines.add(_EditableLine(
        method: PaymentMethod.pix,
        installments: 1,
        amountCtrl: ctrl,
      ));
    }
  }

  TextEditingController _amountToCtrl(double amount) {
    final f = NumberFormat.currency(locale: 'pt_BR', symbol: '', decimalDigits: 2);
    return TextEditingController(text: f.format(amount));
  }

  double _toNumeric(String txt) {
    final cleaned = txt.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(cleaned) ?? 0.0;
  }

  void _onAmountChanged() => setState(() {});

  bool get _hasValue => _lines.any((l) => _toNumeric(l.amountCtrl.text) > 0);

  double get _expectedTotal {
    return _lines.fold<double>(
      0.0,
      (sum, l) => sum + _toNumeric(l.amountCtrl.text),
    );
  }

  @override
  void dispose() {
    for (final l in _lines) {
      l.amountCtrl.removeListener(_onAmountChanged);
      l.amountCtrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final dialogWidth =
        screen.width > 700 ? 640.0 : (screen.width - 40).clamp(320.0, 640.0).toDouble();
    final listMaxHeight = (screen.height * 0.45).clamp(200.0, 420.0).toDouble();

    return AlertDialog(
      title: const Text('Formas de Pagamento'),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      content: SizedBox(
        width: dialogWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cabeçalho
            Row(
              children: const [
                Expanded(
                  child: Text(
                    'Método',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                SizedBox(width: 8),
                SizedBox(
                  width: 75,
                  child: Text(
                    'Parcelas',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                SizedBox(width: 8),
                SizedBox(
                  width: 105,
                  child: Text(
                    'Valor (R\$)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                SizedBox(width: 8),
                SizedBox(width: 40),
              ],
            ),
            const SizedBox(height: 6),

            // Linhas de pagamento
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: listMaxHeight),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _lines.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final line = _lines[index];
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<PaymentMethod>(
                          value: line.method,
                          onChanged: (v) => setState(() => line.method = v ?? line.method),
                          items: PaymentMethod.values
                              .map((pm) => DropdownMenuItem(
                                    value: pm,
                                    child: Text(pm.label),
                                  ))
                              .toList(),
                          decoration: const InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      SizedBox(
                        width: 75,
                        child: DropdownButtonFormField<int>(
                          value: line.installments,
                          onChanged: (v) => setState(() => line.installments = v ?? 1),
                          items: List.generate(12, (i) => i + 1)
                              .map((n) => DropdownMenuItem(
                                    value: n,
                                    child: Text('${n}x'),
                                  ))
                              .toList(),
                          decoration: const InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      SizedBox(
                        width: 105,
                        child: TextFormField(
                          controller: line.amountCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [_currencyFormatter],
                          textAlign: TextAlign.right,
                          decoration: const InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            hintText: '0,00',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      IconButton(
                        tooltip: 'Remover',
                        onPressed: _lines.length == 1
                            ? null
                            : () => setState(() => _lines.removeAt(index)),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // adicionar linha
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    final ctrl = TextEditingController();
                    ctrl.addListener(_onAmountChanged);
                    _lines.add(_EditableLine(
                      method: PaymentMethod.pix,
                      installments: 1,
                      amountCtrl: ctrl,
                    ));
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text('Adicionar pagamento'),
              ),
            ),
          ],
        ),
      ),
      actions: [
        Row(
          children: [
            // botão de parcelas
            TextButton(
              onPressed: _hasValue
                  ? () async {
                      final updated = await showDialog<List<PaymentLine>>(
                        context: context,
                        builder: (_) => ManageInstallmentsDialog(
                          payments: _lines.map((l) {
                            return PaymentLine(
                              method: l.method,
                              installments: l.installments,
                              amount: _toNumeric(l.amountCtrl.text),
                              installmentsDetails: l.details,
                              expectedTotal: _expectedTotal, // ✅ aqui
                            );
                          }).toList(),
                        ),
                      );

                      if (updated != null) {
                        setState(() {
                          _lines.clear();
                          for (final u in updated) {
                            final ctrl = _amountToCtrl(u.amount);
                            ctrl.addListener(_onAmountChanged);
                            _lines.add(_EditableLine(
                              method: u.method,
                              installments: u.installments,
                              amountCtrl: ctrl,
                              details: u.installmentsDetails,
                            ));
                          }
                          _installmentsManaged = true;
                        });
                      }
                    }
                  : null,
              child: const Text('Gerenciar parcelas'),
            ),

            const Spacer(),

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(_installmentsManaged ? 'Fechar' : 'Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (!_installmentsManaged) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Antes, gerencie as parcelas.')),
                  );
                  return;
                }

                final result = <PaymentLine>[];
                for (final l in _lines) {
                  final amount = _toNumeric(l.amountCtrl.text);
                  if (amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Informe um valor válido.')),
                    );
                    return;
                  }
                  result.add(PaymentLine(
                    method: l.method,
                    installments: l.installments,
                    amount: amount,
                    installmentsDetails: l.details,
                    expectedTotal: _expectedTotal, // ✅ aqui também
                  ));
                }
                Navigator.pop(context, result);
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ],
    );
  }
}

class _EditableLine {
  PaymentMethod method;
  int installments;
  final TextEditingController amountCtrl;
  List<Map<String, dynamic>>? details;

  _EditableLine({
    required this.method,
    required this.installments,
    required this.amountCtrl,
    this.details,
  });
}
