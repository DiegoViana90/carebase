final RegExp _emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');

String? validateName(String? value) {
  if (value == null || value.trim().length < 2) return 'Nome inválido';
  return null;
}

String? validateEmail(String? value) {
  if (value == null || !_emailRegex.hasMatch(value.trim())) return 'Email inválido';
  return null;
}

String? validatePassword(String? value) {
  if (value == null || value.length < 4) return 'Senha muito curta';
  return null;
}

String? validateCpf(String? value) {
  if (value == null || !_isValidCpf(value)) return 'CPF inválido';
  return null;
}

String? validateCnpj(String? value) {
  if (value == null || !_isValidCnpj(value)) return 'CNPJ inválido';
  return null;
}

String? validateCpfOrCnpj(String? value) {
  if (value == null) return 'Informe o CPF ou CNPJ';
  return (value.length == 11 && _isValidCpf(value)) ||
         (value.length == 14 && _isValidCnpj(value))
      ? null
      : 'CNPJ ou CPF inválido';
}

// ------------------------
// Validações internas
// ------------------------

bool _isValidCpf(String cpf) {
  cpf = cpf.replaceAll(RegExp(r'\D'), '');
  if (cpf.length != 11 || RegExp(r'^(\d)\1*$').hasMatch(cpf)) return false;
  List<int> digits = cpf.split('').map(int.parse).toList();
  for (int i = 9; i < 11; i++) {
    int sum = 0;
    for (int j = 0; j < i; j++) {
      sum += digits[j] * ((i + 1) - j);
    }
    int checkDigit = (sum * 10) % 11;
    if (checkDigit == 10) checkDigit = 0;
    if (digits[i] != checkDigit) return false;
  }
  return true;
}

bool _isValidCnpj(String cnpj) {
  cnpj = cnpj.replaceAll(RegExp(r'\D'), '');
  if (cnpj.length != 14 || RegExp(r'^(\d)\1*$').hasMatch(cnpj)) return false;
  List<int> digits = cnpj.split('').map(int.parse).toList();
  List<int> multipliers1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
  List<int> multipliers2 = [6, ...multipliers1];

  for (int i = 0; i < 2; i++) {
    var multipliers = i == 0 ? multipliers1 : multipliers2;
    var sum = List.generate(multipliers.length,
            (j) => digits[j] * multipliers[j])
        .reduce((a, b) => a + b);
    var checkDigit = sum % 11 < 2 ? 0 : 11 - (sum % 11);
    if (digits[12 + i] != checkDigit) return false;
  }
  return true;
}
