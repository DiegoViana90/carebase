// lib/enums/payment_method.dart

/// Formas de pagamento aceitas
enum PaymentMethod {
  pix,
  debito,
  credito,
  dinheiro,
}

/// Extensões úteis pro enum
extension PaymentMethodExt on PaymentMethod {
  /// Rótulo amigável pra UI
  String get label {
    switch (this) {
      case PaymentMethod.pix:
        return 'Pix';
      case PaymentMethod.debito:
        return 'Cartão de Débito';
      case PaymentMethod.credito:
        return 'Cartão de Crédito';
      case PaymentMethod.dinheiro:
        return 'Dinheiro';
    }
  }
}

/// Converte o `name` (ex.: "pix", "debito") para enum.
/// Retorna null se não bater com nenhuma opção.
PaymentMethod? paymentMethodFromName(String? name) {
  if (name == null) return null;
  for (final pm in PaymentMethod.values) {
    if (pm.name == name) return pm;
  }
  return null;
}
