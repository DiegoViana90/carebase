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
    required String userName,
  }) async {
    final baseUrl = AppConfig.apiBaseUrl;

    final response = await http.post(
      Uri.parse('$baseUrl/business/test-account'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'businessName': businessName,
        'businessEmail': businessEmail,
        'businessTaxNumber': businessTax,
        'userName': userName,
        'userEmail': userEmail,
        'userPassword': userPassword,
        'userTaxNumber': userCpf,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception(
        jsonDecode(response.body)['message'] ?? 'Erro ao criar conta teste',
      );
    }
  }
}
