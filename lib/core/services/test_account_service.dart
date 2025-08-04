import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:carebase/core/config/app_config.dart';

class TestAccountService {
  static Future<void> createTestAccount({
    required String businessName,
    required String businessEmail,
    required String businessTax,
    required String userEmail,
    required String userCpf,
    required String userPassword,
  }) async {
    final baseUrl = AppConfig.apiBaseUrl;

    // Criar empresa
    final businessResponse = await http.post(
      Uri.parse('$baseUrl/api/business/create-business'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'businessName': businessName,
        'businessEmail': businessEmail,
        'businessTaxNumber': businessTax,
      }),
    );

    if (businessResponse.statusCode != 201) {
      throw Exception(jsonDecode(businessResponse.body)['message'] ?? 'Erro ao criar empresa');
    }

    // Criar usuário
    final userResponse = await http.post(
      Uri.parse('$baseUrl/api/user'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': userEmail,
        'password': userPassword,
        'taxNumber': userCpf,
        'businessTaxNumber': businessTax,
      }),
    );

    if (userResponse.statusCode != 201) {
      throw Exception(jsonDecode(userResponse.body)['message'] ?? 'Erro ao criar usuário');
    }
  }
}
