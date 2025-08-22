import 'package:carebase/enums/payment_method.dart';

class PaymentLine {
  final PaymentMethod method;
  final int installments;
  final double amount;
  final double expectedTotal; // 👈 agora faz parte do modelo
  final List<Map<String, dynamic>>? installmentsDetails;

  PaymentLine({
    required this.method,
    required this.installments,
    required this.amount,
    required this.expectedTotal, // 👈 required
    this.installmentsDetails,
  });
}
