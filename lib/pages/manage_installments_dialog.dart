// PATCHED: ManageInstallmentsDialog
// Fixes expectedTotal calculation and logs everything properly

import 'package:carebase/models/payment_line.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:carebase/enums/payment_method.dart';

class ManageInstallmentsDialog extends StatefulWidget {
  final List<PaymentLine> payments;

  const ManageInstallmentsDialog({super.key, required this.payments});

  @override
  State<ManageInstallmentsDialog> createState() => _ManageInstallmentsDialogState();
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

  _Installment({required this.number, required this.amountController, this.paid = false});
}

class _ManageInstallmentsDialogState extends State<ManageInstallmentsDialog> {
  final _currencyFormatter = TextInputFormatter.withFunction((oldValue, newValue) {
    String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue(text: '');
    if (digits.length > 7) digits = digits.substring(0, 7);
    final value = double.parse(digits) / 100;
    final formatted = NumberFormat.currency(locale: 'pt_BR', symbol: '', decimalDigits: 2).format(value);
    return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
  });

  late List<_InstallmentGroup> groups;

  @override
  void initState() {
    super.initState();

    groups = widget.payments.map((p) {
      final details = p.installmentsDetails;
      final usedDetails = (details != null && details.isNotEmpty)
          ? details
          : List.generate(
              p.installments,
              (i) => InstallmentDetail(
                    paymentInstallmentId: 0,
                    number: i + 1,
                    amount: p.amount / p.installments,
                    dueDate: DateTime.now(),
                    isPaid: false,
                    paidAt: null,
                  ),
            );

      print('\n--- Método: ${p.method.label} ---');
      print('expectedTotal: R\$ ${p.expectedTotal.toStringAsFixed(2)}');
      for (var d in usedDetails) {
        print('Parcela ${d.number}: R\$ ${d.amount.toStringAsFixed(2)} (paga: ${d.isPaid})');
      }

      return _InstallmentGroup(
        method: p.method,
        installments: usedDetails.map((inst) {
          return _Installment(
            number: inst.number,
            amountController: TextEditingController(
              text: NumberFormat.currency(locale: 'pt_BR', symbol: '', decimalDigits: 2).format(inst.amount),
            ),
            paid: inst.isPaid,
          );
        }).toList(),
      );
    }).toList();
  }

  double _toNumeric(String text) {
    final cleaned = text.replaceAll('.', '').replaceAll(',', '.').replaceAll('R\$', '').trim();
    return double.tryParse(cleaned) ?? 0.0;
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
            children: groups.map((group) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  Text(
                    group.method.label.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    children: group.installments.map((installment) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Text('Parcela ${installment.number}', style: const TextStyle(fontWeight: FontWeight.w500)),
                            const SizedBox(width: 6),
                            const Expanded(child: Divider(thickness: 1, color: Colors.black26)),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 150,
                              child: TextFormField(
                                controller: installment.amountController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [_currencyFormatter],
                                textAlign: TextAlign.right,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                  prefixText: 'R\$ ',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Checkbox(
                              value: installment.paid,
                              onChanged: (v) => setState(() => installment.paid = v ?? false),
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
            final result = groups.map((group) {
              final original = widget.payments.firstWhere(
                (p) => p.method == group.method,
                orElse: () => PaymentLine(
                  method: group.method,
                  installments: group.installments.length,
                  amount: 0,
                  expectedTotal: 0,
                ),
              );

              final installments = group.installments.map((inst) {
                final amount = _toNumeric(inst.amountController.text);
                return InstallmentDetail(
                  paymentInstallmentId: 0,
                  number: inst.number,
                  amount: amount,
                  dueDate: DateTime.now(),
                  isPaid: inst.paid,
                  paidAt: inst.paid ? DateTime.now() : null,
                );
              }).toList();

              return PaymentLine(
                method: group.method,
                installments: group.installments.length,
                amount: installments.fold(0.0, (sum, i) => sum + i.amount),
                expectedTotal: original.expectedTotal,
                installmentsDetails: installments,
              );
            }).toList();

            final totalInstallments = result.fold(0.0, (sum, line) => sum + line.amount);
            final expectedTotal = widget.payments.fold(0.0, (sum, line) => sum + line.expectedTotal);

            print('\n==== RESUMO FINAL ====');
            for (var r in result) {
              print('Método: ${r.method.label}');
              for (var i in r.installmentsDetails!) {
                print('  Parcela ${i.number}: R\$ ${i.amount.toStringAsFixed(2)}');
              }
            }
            print('TOTAL PARCELAS: R\$ ${totalInstallments.toStringAsFixed(2)}');
            print('TOTAL ESPERADO: R\$ ${expectedTotal.toStringAsFixed(2)}\n');

            if (totalInstallments.toStringAsFixed(2) != expectedTotal.toStringAsFixed(2)) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Atenção"),
                  content: Text(
                    "A soma das parcelas (R\$ ${totalInstallments.toStringAsFixed(2)})\n"
                    "não confere com o valor total esperado\n"
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

            Navigator.pop(context, result);
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
