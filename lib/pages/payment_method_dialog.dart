// lib/pages/payment_method_dialog.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:carebase/enums/payment_method.dart';

class PaymentLine {
  final PaymentMethod method;
  final int installments; // 1..12
  final double amount;

  PaymentLine({
    required this.method,
    required this.installments,
    required this.amount,
  });

  @override
  String toString() =>
      'PaymentLine(method: ${method.name}, installments: $installments, amount: $amount)';
}

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
    return TextEditingValue(text: s, selection: TextSelection.collapsed(offset: s.length));
  });

  final _lines = <_EditableLine>[];

  @override
  void initState() {
    super.initState();
    if (widget.initialLines?.isNotEmpty == true) {
      for (final l in widget.initialLines!) {
        _lines.add(_EditableLine(
          method: l.method,
          installments: l.installments,
          amountCtrl: _amountToCtrl(l.amount),
        ));
      }
    } else {
      _lines.add(_EditableLine(
        method: PaymentMethod.pix,
        installments: 1,
        amountCtrl: TextEditingController(),
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

  @override
  void dispose() {
    for (final l in _lines) {
      l.amountCtrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    // largura fixa para evitar IntrinsicWidth solicitar intrinsics do scrollable
    final dialogWidth = screen.width > 700 ? 640.0 : (screen.width - 40).clamp(320.0, 640.0).toDouble();
    // altura finita para a lista
    final listMaxHeight = (screen.height * 0.45).clamp(200.0, 420.0).toDouble();

    return AlertDialog(
      title: const Text('Pagamento'),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      content: SizedBox(
        width: dialogWidth, // <- largura fixa
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // cabeçalho
            Row(
              children: const [
                Expanded(child: Text('Tipo de pagamento', style: TextStyle(fontWeight: FontWeight.w600))),
                SizedBox(width: 8),
                SizedBox(width: 90, child: Text('Parcelas', style: TextStyle(fontWeight: FontWeight.w600))),
                SizedBox(width: 8),
                SizedBox(width: 120, child: Text('Valor (R\$)', style: TextStyle(fontWeight: FontWeight.w600))),
                SizedBox(width: 8),
                SizedBox(width: 40),
              ],
            ),
            const SizedBox(height: 6),

            // linhas (com altura finita)
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
                    children: [
                      // método
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

                      // parcelas 1x..12x
                      SizedBox(
                        width: 90,
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

                      // valor
                      SizedBox(
                        width: 120,
                        child: TextFormField(
                          controller: line.amountCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [_currencyFormatter],
                          decoration: const InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            hintText: '0,00',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // remover
                      SizedBox(
                        width: 40,
                        child: IconButton(
                          tooltip: 'Remover',
                          onPressed: _lines.length == 1 ? null : () => setState(() => _lines.removeAt(index)),
                          icon: const Icon(Icons.delete_outline),
                        ),
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
                    _lines.add(_EditableLine(
                      method: PaymentMethod.pix,
                      installments: 1,
                      amountCtrl: TextEditingController(),
                    ));
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text('Adicionar procedimento'),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
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
              ));
            }
            Navigator.pop(context, result);
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}

class _EditableLine {
  PaymentMethod method;
  int installments;
  final TextEditingController amountCtrl;

  _EditableLine({
    required this.method,
    required this.installments,
    required this.amountCtrl,
  });
}
