import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  // Cambia por tu URL del backend cuando lo despliegues en HuggingFace
  static const String _baseUrl = 'https://HDPa-diagnostico-api.hf.space';

  /// Obtiene el token Firebase del usuario actual
  static Future<String> _getToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');
    return await user.getIdToken() ?? '';
  }

  /// POST /predict — envía síntomas y devuelve diagnóstico
  static Future<Map<String, dynamic>> predict(List<String> sintomas) async {
    final token = await _getToken();

    final response = await http.post(
      Uri.parse('$_baseUrl/predict'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'sintomas': sintomas, 'id_token': token}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Error al predecir');
    }
  }

  /// POST /history — obtiene historial del usuario
  static Future<Map<String, dynamic>> getHistory({int limite = 20}) async {
    final token = await _getToken();

    final response = await http.post(
      Uri.parse('$_baseUrl/history?limite=$limite'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id_token': token}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al cargar el historial');
    }
  }

  /// POST /auth/register — registra nuevo usuario
  static Future<void> registerUser({
    required String email,
    required String password,
    required String nombre,
    required String fechaNacimiento,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'nombre': nombre,
        'fecha_nacimiento': fechaNacimiento,
      }),
    );

    if (response.statusCode != 201) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Error al registrar');
    }
  }

  /// DELETE /auth/delete — borra la cuenta del usuario y sus datos en Firestore
  static Future<void> deleteAccount() async {
    final token = await _getToken();

    final response = await http.delete(
      Uri.parse('$_baseUrl/auth/delete'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id_token': token}),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Error al eliminar la cuenta');
    }
  }
}