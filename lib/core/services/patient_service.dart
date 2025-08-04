import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:carebase/core/config/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PatientService {
  static Future<List<Map<String, dynamic>>> fetchAllPatients() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      throw Exception('Token de autenticação não encontrado.');
    }

    final url = Uri.parse('${AppConfig.apiBaseUrl}/Patients');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List data = json['data'];
      return data.cast<Map<String, dynamic>>();
    } else if (response.statusCode == 401) {
      throw Exception('Sessão expirada. Faça login novamente.');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erro ao buscar pacientes.');
    }
  }

  static Future<void> createPatient({
    required String name,
    String? cpf,
    String? phone,
    String? email,
    String? profession,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) throw Exception('Token de autenticação não encontrado.');

    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/Patients'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'cpf': cpf,
        'phone': phone,
        'email': email,
        'profession': profession,
      }),
    );

    if (response.statusCode != 201) {
      final json = jsonDecode(response.body);
      throw Exception(json['message'] ?? 'Erro ao cadastrar paciente.');
    }
  }
}
