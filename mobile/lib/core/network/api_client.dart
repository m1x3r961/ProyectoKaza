import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'supabase_config.dart';

class ApiException implements Exception {
  final String message;
  final int status;
  ApiException(this.message, this.status);
  @override
  String toString() => message;
}

class ApiClient {
  final http.Client Function() _clientFactory;
  final String? Function() _accessToken;
  ApiClient(
      {http.Client Function()? clientFactory, String? Function()? accessToken})
      : _clientFactory = clientFactory ?? http.Client.new,
        _accessToken = accessToken ??
            (() => SupabaseConfig.client.auth.currentSession?.accessToken);
  static const baseUrl = String.fromEnvironment('API_BASE_URL',
      defaultValue: 'http://localhost:3000');
  static String newId() {
    final r = Random.secure();
    final b = List<int>.generate(16, (_) => r.nextInt(256));
    b[6] = (b[6] & 15) | 64;
    b[8] = (b[8] & 63) | 128;
    final h = b.map((v) => v.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }

  Future<dynamic> request(String path,
      {String method = 'GET',
      Object? body,
      bool authenticated = true,
      String? key}) async {
    final token = authenticated ? _accessToken() : null;
    if (authenticated && token == null)
      throw ApiException('Inicia sesión para continuar.', 401);
    final req = http.Request(method, Uri.parse('$baseUrl$path'));
    req.headers['Content-Type'] = 'application/json';
    if (authenticated) req.headers['Authorization'] = 'Bearer $token';
    if (key != null) req.headers['Idempotency-Key'] = key;
    if (body != null) req.body = jsonEncode(body);
    final client = _clientFactory();
    try {
      final response = await http.Response.fromStream(
              await client.send(req).timeout(const Duration(seconds: 35)))
          .timeout(const Duration(seconds: 35));
      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        throw ApiException(
            'Respuesta no válida del servidor.', response.statusCode);
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = data is Map ? data['message'] : null;
        throw ApiException(
            message is String ? message : 'No se pudo completar la operación.',
            response.statusCode);
      }
      return data;
    } finally {
      client.close();
    }
  }
}
