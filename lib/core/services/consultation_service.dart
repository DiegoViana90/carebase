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

  static Future<void> updateConsultationDetails({
    required int consultationId,
    required String titulo1,
    required String titulo2,
    required String titulo3,
    required String texto1,
    required String texto2,
    required String texto3,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      throw Exception('Token de autenticação não encontrado.');
    }

    final body = {
      'titulo1': titulo1,
      'titulo2': titulo2,
      'titulo3': titulo3,
      'texto1': texto1,
      'texto2': texto2,
      'texto3': texto3,
    };

    final response = await http.put(
      Uri.parse('${AppConfig.apiBaseUrl}/Consultations/$consultationId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      final json = jsonDecode(response.body);
      throw Exception(json['message'] ?? 'Erro ao atualizar consulta.');
    }
  }

  static Future<List<Map<String, dynamic>>> fetchAllConsultations() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      throw Exception('Token de autenticação não encontrado.');
    }

    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/Consultations'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);

      if (json is Map<String, dynamic> && json.containsKey('data')) {
        final data = json['data'];
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      }

      throw Exception('Formato inesperado na resposta da API.');
    } else {
      final json = jsonDecode(response.body);
      throw Exception(json['message'] ?? 'Erro ao buscar consultas.');
    }
  }
}
