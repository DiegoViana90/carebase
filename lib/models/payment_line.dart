import 'package:carebase/enums/payment_method.dart';

class PaymentLine {
  final PaymentMethod method;
  final int installments;
  final double amount;
  final double expectedTotal;
  final List<InstallmentDetail>? installmentsDetails;

  PaymentLine({
    required this.method,
    required this.installments,
    required this.amount,
    required this.expectedTotal,
    this.installmentsDetails,
  });

  factory PaymentLine.fromJson(Map<String, dynamic> json) {
    final rawMethod = (json['method'] as num?)?.toInt() ?? 0;
    final safeIdx = rawMethod.clamp(0, PaymentMethod.values.length - 1);
    return PaymentLine(
      method: PaymentMethod.values[safeIdx],
      installments: (json['installments'] as num?)?.toInt() ?? 1,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      expectedTotal: ((json['expectedTotal'] ?? json['amount']) as num?)?.toDouble() ?? 0.0,
      installmentsDetails: (json['installmentsDetails'] as List<dynamic>?)
          ?.map((e) => InstallmentDetail.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'method': method.index,
      'installments': installments,
      'amount': amount,
      'expectedTotal': expectedTotal,
      if (installmentsDetails != null)
        'installmentsDetails': installmentsDetails!.map((i) => i.toJson()).toList(),
    };
  }
}

class InstallmentDetail {
  final int paymentInstallmentId;
  final int number;
  final double amount;
  final DateTime dueDate;
  final bool isPaid;
  final DateTime? paidAt;

  InstallmentDetail({
    required this.paymentInstallmentId,
    required this.number,
    required this.amount,
    required this.dueDate,
    required this.isPaid,
    this.paidAt,
  });

  factory InstallmentDetail.fromJson(Map<String, dynamic> json) {
    return InstallmentDetail(
      paymentInstallmentId: (json['paymentInstallmentId'] as num?)?.toInt() ?? 0,
      number: (json['number'] as num?)?.toInt() ?? 1,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      dueDate: DateTime.parse(json['dueDate'] as String),
      isPaid: json['isPaid'] as bool? ?? false,
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paymentInstallmentId': paymentInstallmentId,
      'number': number,
      'amount': amount,
      'dueDate': dueDate.toIso8601String(),
      'isPaid': isPaid,
      'paidAt': paidAt?.toIso8601String(),
    };
  }
}
