import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:carebase/core/config/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConsultationService {
  static Future<void> createConsultation({
    required int patientId,
    required DateTime startDate,
    DateTime? endDate,
    String? notes,
    double? amountPaid,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      throw Exception('Token de autenticação não encontrado.');
    }

    final body = {
      'patientId': patientId,
      'startDate': startDate.toIso8601String(),
      if (endDate != null) 'endDate': endDate.toIso8601String(),
      if (notes != null) 'notes': notes,
      if (amountPaid != null) 'amountPaid': amountPaid,
    };

    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/Consultations'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 201) {
      final json = jsonDecode(response.body);
      throw Exception(json['message'] ?? 'Erro ao agendar consulta.');
    }
  }
}
