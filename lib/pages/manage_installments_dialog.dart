import 'package:carebase/models/payment_line.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:carebase/enums/payment_method.dart';
import 'payment_method_dialog.dart';

class ManageInstallmentsDialog extends StatefulWidget {
  final List<PaymentLine> payments;

  const ManageInstallmentsDialog({super.key, required this.payments});

  @override
  State<ManageInstallmentsDialog> createState() =>
      _ManageInstallmentsDialogState();
}

class _ManageInstallmentsDialogState extends State<ManageInstallmentsDialog> {
  final _currencyFormatter = TextInputFormatter.withFunction((
    oldValue,
    newValue,
  ) {
    String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue(text: '');
    if (digits.length > 7) digits = digits.substring(0, 7); // limit 99999,99
    final value = double.parse(digits) / 100;
    final formatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: '',
      decimalDigits: 2,
    );
    final formatted = formatter.format(value);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  });

  late List<_InstallmentGroup> groups;

  @override
  void initState() {
    super.initState();

    groups =
        widget.payments.map((p) {
          final details =
              p.installmentsDetails ??
              List.generate(
                p.installments,
                (i) => {
                  'number': i + 1,
                  'value': p.amount / p.installments,
                  'paid': false,
                },
              );

          return _InstallmentGroup(
            method: p.method,
            installments:
                details.map((inst) {
                  return _Installment(
                    number: inst['number'] as int,
                    amountController: TextEditingController(
                      text: NumberFormat.currency(
                        locale: 'pt_BR',
                        symbol: '',
                        decimalDigits: 2,
                      ).format(inst['value']),
                    ),
                    paid: inst['paid'] as bool,
                  );
                }).toList(),
          );
        }).toList();
  }

  double _toNumeric(String text) {
    final cleaned = text.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(cleaned.replaceAll('R\$', '').trim()) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Gerenciar parcelas'),
      content: SizedBox(
        width: 500,
        height: 420,
        child: SingleChildScrollView(
          child: Column(
            children:
                groups.map((group) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(),
                      Text(
                        group.method.label.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Column(
                        children:
                            group.installments.map((installment) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      'Parcela ${installment.number}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Expanded(
                                      child: Divider(
                                        thickness: 1,
                                        color: Colors.black26,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    SizedBox(
                                      width: 150,
                                      child: TextFormField(
                                        controller:
                                            installment.amountController,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [_currencyFormatter],
                                        textAlign: TextAlign.right,
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          border: OutlineInputBorder(),
                                          prefixText: 'R\$ ',
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Checkbox(
                                      value: installment.paid,
                                      onChanged: (v) {
                                        setState(
                                          () => installment.paid = v ?? false,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                      ),
                    ],
                  );
                }).toList(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar'),
        ),
        ElevatedButton(
          onPressed: () {
            // Build the new result list
            final result =
                groups.map((group) {
                  return PaymentLine(
                    method: group.method,
                    installments: group.installments.length,
                    amount: group.installments.fold(
                      0.0,
                      (sum, inst) =>
                          sum + _toNumeric(inst.amountController.text),
                    ),
                    expectedTotal:
                        widget
                            .payments
                            .first
                            .expectedTotal, // ✅ agora salva junto
                    installmentsDetails:
                        group.installments.map((inst) {
                          return {
                            'number': inst.number,
                            'value': _toNumeric(inst.amountController.text),
                            'paid': inst.paid,
                          };
                        }).toList(),
                  );
                }).toList();

            final totalInstallments = result.fold(
              0.0,
              (sum, line) => sum + line.amount,
            );

            final expectedTotal = widget.payments.first.expectedTotal;
            // Validate against expected total
            if (totalInstallments.toStringAsFixed(2) !=
                expectedTotal.toStringAsFixed(2)) {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text("Atenção"),
                      content: Text(
                        "A soma das parcelas (R\$ ${totalInstallments.toStringAsFixed(2)}) "
                        "não confere com o valor total esperado "
                        "(R\$ ${expectedTotal.toStringAsFixed(2)}).\n\n"
                        "Por favor, ajuste os valores antes de salvar.",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("OK"),
                        ),
                      ],
                    ),
              );
              return;
            }

            // Close only if valid
            Navigator.pop(context, result);
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _InstallmentGroup {
  final PaymentMethod method;
  final List<_Installment> installments;

  _InstallmentGroup({required this.method, required this.installments});
}

class _Installment {
  final int number;
  final TextEditingController amountController;
  bool paid;

  _Installment({
    required this.number,
    required this.amountController,
    this.paid = false,
  });
}
