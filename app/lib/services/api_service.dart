import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ApiService {
  String? token;

  String get baseUrl {
    const desdeEntorno = String.fromEnvironment('API_URL');
    if (desdeEntorno.isNotEmpty) return desdeEntorno;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

  void cerrarSesion() => token = null;

  Future<dynamic> enviar(
    String metodo,
    String ruta, {
    Map<String, dynamic>? cuerpo,
    Map<String, String>? consulta,
  }) async {
    final uri = Uri.parse('$baseUrl$ruta').replace(
      queryParameters: (consulta == null || consulta.isEmpty) ? null : consulta,
    );
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    http.Response respuesta;
    try {
      switch (metodo) {
        case 'GET':
          respuesta = await http.get(uri, headers: headers);
        case 'POST':
          respuesta = await http.post(uri, headers: headers, body: jsonEncode(cuerpo ?? {}));
        case 'PUT':
          respuesta = await http.put(uri, headers: headers, body: jsonEncode(cuerpo ?? {}));
        case 'PATCH':
          respuesta = await http.patch(uri, headers: headers, body: jsonEncode(cuerpo ?? {}));
        default:
          throw ApiException('Método no soportado');
      }
    } catch (error) {
      if (error is ApiException) rethrow;
      throw ApiException('No se pudo conectar con la API en $baseUrl');
    }

    final texto = utf8.decode(respuesta.bodyBytes);
    if (respuesta.statusCode >= 200 && respuesta.statusCode < 300) {
      if (texto.isEmpty) return null;
      final tipo = respuesta.headers['content-type'] ?? '';
      if (tipo.contains('text/csv')) return texto;
      return jsonDecode(texto);
    }

    var mensaje = 'Error ${respuesta.statusCode}';
    try {
      final data = jsonDecode(texto);
      if (data is Map && data['error'] != null) mensaje = data['error'].toString();
    } catch (_) {}
    throw ApiException(mensaje);
  }
}
